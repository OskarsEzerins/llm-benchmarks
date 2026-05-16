require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large, :initial_small, :initial_medium, :initial_large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @initial_small = @small
    @initial_medium = @medium
    @initial_large = @large
    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase
    return "Invalid license plate" if plate.empty?
    return "Invalid car size" unless %w[small medium large].include?(size)

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
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    return "No car found" if plate.empty?

    %i[small medium large].each do |spot_type|
      car = @parking_spots[spot_type].find { |c| c[:plate] == plate }
      if car
        @parking_spots[spot_type].delete(car)
        case spot_type
        when :small then @small += 1
        when :medium then @medium += 1
        when :large then @large += 1
        end
        return exit_status(plate)
      end
    end
    "No car found"
  end

  def shuffle_large(kar)
    # Find a medium car in a large spot
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium > 0
      # Move that medium car to a medium spot
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium -= 1
      # Now park the large car in the freed large spot
      @parking_spots[:large] << kar
      # @large count remains the same (one freed, one used)
      parking_status(kar, 'large')
    else
      "No space available"
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
      "No car found"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24
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
    return 0.0 if duration_hours.nil? || duration_hours < 0
    size = car_size.to_s.downcase
    return 0.0 unless %w[small medium large].include?(size)

    # Grace period: first 15 minutes (0.25 hours) free
    return 0.0 if duration_hours <= 0.25

    # Round up to next full hour
    hours = duration_hours.ceil
    rate = RATES[size]
    total = hours * rate
    [total, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str = size.to_s.downcase

    # Validate input
    return { success: false, message: "Invalid license plate" } if plate_str.empty?
    return { success: false, message: "Invalid car size" } unless %w[small medium large].include?(size_str)

    result = @garage.admit_car(plate_str, size_str)
    if result.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @active_tickets[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    return { success: false, message: "Invalid license plate" } if plate_str.empty?

    ticket = @active_tickets[plate_str]
    return { success: false, message: "No active ticket found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)
    @active_tickets.delete(plate_str)

    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    small_available = @garage.small
    medium_available = @garage.medium
    large_available = @garage.large
    total_occupied = (@garage.initial_small + @garage.initial_medium + @garage.initial_large) -
                     (small_available + medium_available + large_available)
    total_available = small_available + medium_available + large_available

    {
      small_available: small_available,
      medium_available: medium_available,
      large_available: large_available,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end