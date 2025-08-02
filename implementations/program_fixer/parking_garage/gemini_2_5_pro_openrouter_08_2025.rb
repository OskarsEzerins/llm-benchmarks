require 'securerandom'
require 'time'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @initial_capacities = { small: @small, medium: @medium, large: @large }

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate, car_size)
    car = { plate: license_plate, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        'small'
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        'medium'
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        'large'
      else
        nil # No space
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        'medium'
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        'large'
      else
        nil # No space
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        'large'
      else
        # Try to shuffle a smaller car out of a large spot
        shuffle_for_large(car)
      end
    else
      nil # Invalid car size
    end
  end

  def exit_car(license_plate)
    found_car = nil
    spot_type = nil

    @parking_spots.each do |type, cars|
      car_to_remove = cars.find { |c| c[:plate] == license_plate }
      if car_to_remove
        found_car = car_to_remove
        spot_type = type
        cars.delete(car_to_remove)
        break
      end
    end

    if found_car
      case spot_type
      when :small
        @small += 1
      when :medium
        @medium += 1
      when :large
        @large += 1
      end
      return true # Indicate success
    end

    false # Indicate failure (car not found)
  end

  def total_capacity
    @initial_capacities.values.sum
  end

  private

  def shuffle_for_large(large_car)
    # Prefer moving a medium car to a medium spot
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium > 0
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium -= 1 # A medium spot is now occupied
      # The large spot is now free, but will be immediately taken
      @parking_spots[:large] << large_car
      return 'large'
    end

    # Then try moving a small car to a small or medium spot
    small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if small_in_large
      if @small > 0 # Prefer moving to a small spot
        @parking_spots[:large].delete(small_in_large)
        @parking_spots[:small] << small_in_large
        @small -= 1 # A small spot is now occupied
        @parking_spots[:large] << large_car
        return 'large'
      elsif @medium > 0 # Otherwise, try a medium spot
        @parking_spots[:large].delete(small_in_large)
        @parking_spots[:medium] << small_in_large
        @medium -= 1 # A medium spot is now occupied
        @parking_spots[:large] << large_car
        return 'large'
      end
    end

    nil # Shuffling failed
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size
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
    small: 2.0,
    medium: 3.0,
    large: 5.0
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  GRACE_PERIOD_HOURS = 0.25 # 15 minutes

  def calculate_fee(car_size, duration_hours)
    # Input validation
    return 0.0 unless car_size.is_a?(String) && duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours < 0

    rate_key = car_size.downcase.to_sym
    return 0.0 unless RATES.key?(rate_key)

    # Grace period
    return 0.0 if duration_hours <= GRACE_PERIOD_HOURS

    rate = RATES[rate_key]
    max_fee = MAX_FEE[car_size.downcase]

    # Round up to the next full hour
    billed_hours = duration_hours.ceil
    total_fee = billed_hours * rate

    [total_fee, max_fee].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(license_plate, car_size)
    # Input validation and sanitization
    plate_str = license_plate.to_s.strip
    return { success: false, message: "Invalid license plate" } if plate_str.empty?

    size_str = car_size.to_s.downcase.strip
    unless ['small', 'medium', 'large'].include?(size_str)
      return { success: false, message: "Invalid car size" }
    end

    if @active_tickets.key?(plate_str)
      return { success: false, message: "Car with license plate no. #{plate_str} is already parked" }
    end

    spot_type = @garage.admit_car(plate_str, size_str)

    if spot_type
      ticket = ParkingTicket.new(plate_str, size_str)
      @active_tickets[plate_str] = ticket
      {
        success: true,
        message: "car with license plate no. #{plate_str} is parked at #{spot_type}",
        ticket: ticket
      }
    else
      { success: false, message: "No space available" }
    end
  end

  def exit_car(license_plate)
    plate_str = license_plate.to_s.strip
    ticket = @active_tickets[plate_str]

    unless ticket
      return { success: false, message: "Ticket not found for license plate no. #{plate_str}" }
    end

    unless ticket.valid?
      @active_tickets.delete(plate_str)
      @garage.exit_car(plate_str) # Still remove car from garage
      return { success: false, message: "Ticket for license plate no. #{plate_str} has expired" }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)

    if @garage.exit_car(plate_str)
      @active_tickets.delete(plate_str)
      {
        success: true,
        message: "car with license plate no. #{plate_str} exited",
        fee: fee,
        duration_hours: duration
      }
    else
      # This case should ideally not be reached if tickets are in sync with the garage
      { success: false, message: "Error: Car with license plate no. #{plate_str} found in ticket system but not in garage." }
    end
  end

  def garage_status
    total_occupied = @active_tickets.size
    total_available = @garage.small + @garage.medium + @garage.large
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(license_plate)
    @active_tickets[license_plate.to_s.strip]
  end
end