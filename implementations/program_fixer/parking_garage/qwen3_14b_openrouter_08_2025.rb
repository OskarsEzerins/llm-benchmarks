require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small:    [],
      medium:   [],
      large:    []
    }
  end

  def admit_car(license_plate_no, car_size)
    # Validate car_size
    car_size = car_size.downcase if car_size
    return "Invalid car size" unless ['small', 'medium', 'large'].include?(car_size)

    # Convert license plate to string
    license_plate_no = license_plate_no.to_s

    # Create car hash
    car = { plate: license_plate_no, size: car_size }

    case car_size
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
        parking_status
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
        shuffle_medium(car)
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
    # Convert license plate to string
    license_plate_no = license_plate_no.to_s

    small_car  = @parking_spots[:small].find { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:large].find { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      exit_status(license_plate_no)
    else
      exit_status
    end
  end

  def shuffle_medium(car)
    return unless @medium > 0

    # Find a medium car in large spots
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }

    if medium_in_large
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium += 1
    end

    # Find a small spot
    if @small > 0
      @parking_spots[:small] << car
      @small -= 1
      parking_status(car, 'small')
    else
      # No space available
      parking_status
    end
  end

  def shuffle_large(car)
    return unless @medium > 0

    # Find a medium car in large spots
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }

    if medium_in_large
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium += 1
    end

    # Find a large spot
    if @large > 0
      @parking_spots[:large] << car
      @large -= 1
      parking_status(car, 'large')
    else
      # No space available
      parking_status
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
    plate ? "car with license plate no. #{plate} exited" : "Ghost car?"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @license_plate = license_plate.to_s
    @car_size = car_size.downcase
    @entry_time = entry_time
    @id = "TK-#{SecureRandom.uuid}"
  end

  def duration_hours
    duration = Time.now - @entry_time
    (duration / 3600).to_f
  end

  def valid?
    duration_hours <= 23.999
  end
end

class ParkingFeeCalculator
  RATES = {
    small: 2.0,
    medium: 3.0,
    large: 5.0
  }

  MAX_FEE = {
    small: 20.0,
    medium: 30.0,
    large: 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= 0.25

    # Grace period is 0.25 hours (15 minutes)
    duration = duration_hours - 0.25
    duration = 0.0 if duration < 0.0

    # Round up to the next full hour
    hours = duration.ceil

    # Use the correct rate for the car size
    rate = RATES[car_size.downcase.to_sym] || RATES.values.first

    # Calculate the fee
    fee = hours * rate

    # Apply daily maximum
    max_fee = MAX_FEE[car_size.downcase] || MAX_FEE.values.first
    [fee, max_fee].min
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(license_plate, car_size)
    # Validate input
    return { success: false, message: "Invalid license plate" } if license_plate.nil? || license_plate.to_s.strip.empty?
    return { success: false, message: "Invalid car size" } unless ['small', 'medium', 'large'].include?(car_size.downcase)

    # Normalize inputs
    license_plate = license_plate.to_s.strip
    car_size = car_size.downcase

    # Attempt to park
    result = @garage.admit_car(license_plate, car_size)

    # If parking was successful
    if result.include?("car with license plate no.")
      ticket = ParkingTicket.new(license_plate, car_size)
      @tix_in_flight[license_plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(license_plate)
    # Validate input
    return { success: false, message: "Invalid license plate" } if license_plate.nil? || license_plate.to_s.strip.empty?
    license_plate = license_plate.to_s.strip

    # Get ticket
    ticket = @tix_in_flight[license_plate]
    return { success: false, message: "No ticket found for license plate #{license_plate}" } unless ticket

    # Calculate fee
    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)

    # Exit car
    @garage.exit_car(license_plate)

    # Remove ticket
    @tix_in_flight.delete(license_plate)

    { success: true, message: "car with license plate no. #{license_plate} exited", fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: (@garage.parking_spots[:small].size + @garage.parking_spots[:medium].size + @garage.parking_spots[:large].size),
      total_available: (@garage.small + @garage.medium + @garage.large),
      active_tickets: @tix_in_flight.size
    }
  end

  def find_ticket(license_plate)
    license_plate = license_plate.to_s.strip
    @tix_in_flight[license_plate] || nil
  end
end