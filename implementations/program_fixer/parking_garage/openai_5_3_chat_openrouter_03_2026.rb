require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  VALID_SIZES = %w[small medium large]

  def initialize(small, medium, large)
    @small_capacity  = small.to_i
    @medium_capacity = medium.to_i
    @large_capacity  = large.to_i

    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def small
    @small_capacity - @parking_spots[:small].size
  end

  def medium
    @medium_capacity - @parking_spots[:medium].size
  end

  def large
    @large_capacity - @parking_spots[:large].size
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)
    return "No space available" unless plate && size

    car = { plate: plate, size: size }

    case size
    when 'small'
      if small > 0
        @parking_spots[:small] << car
        return parking_status(car, 'small')
      elsif medium > 0
        @parking_spots[:medium] << car
        return parking_status(car, 'medium')
      elsif large > 0
        @parking_spots[:large] << car
        return parking_status(car, 'large')
      end
    when 'medium'
      if medium > 0
        @parking_spots[:medium] << car
        return parking_status(car, 'medium')
      elsif large > 0
        @parking_spots[:large] << car
        return parking_status(car, 'large')
      end
    when 'large'
      if large > 0
        @parking_spots[:large] << car
        return parking_status(car, 'large')
      else
        return shuffle_large(car)
      end
    end

    "No space available"
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return "Car not found" unless plate

    [:small, :medium, :large].each do |type|
      car = @parking_spots[type].find { |c| c[:plate] == plate }
      if car
        @parking_spots[type].delete(car)
        return exit_status(plate)
      end
    end

    "Car not found"
  end

  def shuffle_large(car)
    return "No space available" unless medium > 0

    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    return "No space available" unless medium_in_large

    @parking_spots[:large].delete(medium_in_large)
    @parking_spots[:medium] << medium_in_large
    @parking_spots[:large] << car

    parking_status(car, 'large')
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate)
    "car with license plate no. #{plate} exited"
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?
    p = plate.to_s.strip
    return nil if p.empty?
    p
  end

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.downcase.strip
    VALID_SIZES.include?(s) ? s : nil
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0)
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    hours = duration_hours.to_f
    return 0.0 if hours <= GRACE_PERIOD
    return 0.0 unless RATES.key?(size)

    billable = (hours - GRACE_PERIOD)
    rounded_hours = billable.ceil
    fee = rounded_hours * RATES[size]

    [fee.to_f, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s
    verdict = @garage.admit_car(plate_str, size)

    if verdict.include?("parked")
      ticket = ParkingTicket.new(plate_str, size)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tix_in_flight[plate_str]
    return { success: false, message: "Ticket not found" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)

    @tix_in_flight.delete(plate_str)

    {
      success: true,
      message: result,
      fee: fee.to_f,
      duration_hours: duration
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @tix_in_flight.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end