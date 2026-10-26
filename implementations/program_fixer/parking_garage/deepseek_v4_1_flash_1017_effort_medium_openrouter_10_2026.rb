require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large = [large.to_i, 0].max
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)
    return "No space available" if plate.empty? || size.nil?

    case size
    when 'small'
      return park_car(plate, size, :small) if @small > 0
      return park_car(plate, size, :medium) if @medium > 0
      return park_car(plate, size, :large) if @large > 0
      "No space available"
    when 'medium'
      return park_car(plate, size, :medium) if @medium > 0
      return park_car(plate, size, :large) if @large > 0
      shuffle_medium(plate, size) || "No space available"
    when 'large'
      return park_car(plate, size, :large) if @large > 0
      shuffle_large(plate, size) || "No space available"
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    spot = [:small, :medium, :large].find do |s|
      @parking_spots[s].any? { |c| c[:plate] == plate }
    end

    if spot
      car = @parking_spots[spot].find { |c| c[:plate] == plate }
      @parking_spots[spot].delete(car)
      increment_available(spot)
      "car with license plate no. #{plate} exited"
    else
      "car with license plate no. #{plate} not found"
    end
  end

  def shuffle_medium(plate, size)
    if @small > 0
      small_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if small_in_medium
        move_car(small_in_medium, :medium, :small)
        return park_car(plate, size, :medium)
      end
    end

    if @small > 0
      small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_in_large
        move_car(small_in_large, :large, :small)
        return park_car(plate, size, :large)
      end
    end

    if @medium > 0
      small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_in_large
        move_car(small_in_large, :large, :medium)
        return park_car(plate, size, :large)
      end
    end

    nil
  end

  def shuffle_large(plate, size)
    if @medium > 0
      medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      if medium_in_large
        move_car(medium_in_large, :large, :medium)
        return park_car(plate, size, :large)
      end
    end

    if @small > 0
      small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_in_large
        move_car(small_in_large, :large, :small)
        return park_car(plate, size, :large)
      end
    end

    if @medium > 0
      small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_in_large
        move_car(small_in_large, :large, :medium)
        return park_car(plate, size, :large)
      end
    end

    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium == 0 && @small > 0
      small_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if small_in_medium
        move_car(small_in_medium, :medium, :small)
        move_car(medium_in_large, :large, :medium)
        return park_car(plate, size, :large)
      end
    end

    nil
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space
    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    return 'No car found' if plate.nil?
    "car with license plate no. #{plate} exited"
  end

  private

  def normalize_plate(license_plate_no)
    license_plate_no.to_s.strip
  end

  def normalize_size(car_size)
    size = car_size.to_s.strip.downcase
    return size if %w[small medium large].include?(size)
    nil
  end

  def park_car(plate, size, spot)
    @parking_spots[spot] << { plate: plate, size: size }
    decrement_available(spot)
    "car with license plate no. #{plate} is parked at #{spot}"
  end

  def move_car(car, from, to)
    @parking_spots[from].delete(car)
    @parking_spots[to] << car
    increment_available(from)
    decrement_available(to)
  end

  def decrement_available(spot)
    case spot
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
  end

  def increment_available(spot)
    case spot
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time || Time.now
  end

  alias license license_plate

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.hex(8)}"
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

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    hours = begin
      Float(duration_hours)
    rescue StandardError
      nil
    end

    return 0.0 if hours.nil? || hours < 0.0 || hours.nan? || hours.infinite?
    return 0.0 if hours <= GRACE_PERIOD_HOURS

    billable_hours = hours - GRACE_PERIOD_HOURS
    rounded_hours = billable_hours.ceil
    total = rounded_hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **options)
    small_spots = options[:small_spots] if options.key?(:small_spots)
    medium_spots = options[:medium_spots] if options.key?(:medium_spots)
    large_spots = options[:large_spots] if options.key?(:large_spots)

    @garage = ParkingGarage.new(small_spots || 0, medium_spots || 0, large_spots || 0)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str = size.to_s.strip.downcase

    if @tix_in_flight.key?(plate_str)
      return { success: false, message: "car with license plate no. #{plate_str} is already parked" }
    end

    result = @garage.admit_car(plate_str, size_str)

    if result.start_with?('car with license plate no.') && result.include?('is parked at')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tix_in_flight[plate_str]
    return { success: false, message: "car with license plate no. #{plate_str} not found" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)

    if result.include?('exited')
      @tix_in_flight.delete(plate_str)
      { success: true, message: result, fee: fee, duration_hours: duration }
    else
      { success: false, message: result, fee: fee, duration_hours: duration }
    end
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
    @tix_in_flight[plate.to_s.strip]
  end
end