require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i
    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s
    size  = car_size.to_s.downcase
    return "No space available" unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car) || "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    found = nil

    @parking_spots.each do |spot_type, cars|
      found = cars.detect { |c| c[:plate] == plate }
      if found
        cars.delete(found)
        case spot_type
        when :small then @small += 1
        when :medium then @medium += 1
        when :large then @large += 1
        end
        return exit_status(plate)
      end
    end

    exit_status(nil)
  end

  def shuffle_large(kar)
    # Try to move a medium car from a large spot to a medium spot
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium > 0
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium -= 1
      @large += 1  # freed a large spot

      @parking_spots[:large] << kar
      @large -= 1
      parking_status(kar, 'large')
    else
      nil
    end
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      "No space available"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id           = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size     = car_size.to_s.downcase
    @entry_time   = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24.0
  end
end

class ParkingFeeCalculator
  RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 if duration_hours.nil? || duration_hours < 0

    rate = RATES[size]
    max  = MAX_FEE[size]

    # Grace period: first 0.25 hours free
    if duration_hours <= 0.25
      0.0
    else
      hours = (duration_hours - 0.25).ceil
      fee = hours * rate
      [fee, max].min
    end
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage         = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets        = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)
    if verdict.include?('parked')
      ticket               = ParkingTicket.new(plate, size)
      @tickets[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tickets[plate_str]
    return { success: false, message: "No ticket found for #{plate_str}" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)

    @tickets.delete(plate_str)

    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @garage.parking_spots.values.map(&:size).sum,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s]
  end
end