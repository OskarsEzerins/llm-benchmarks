require 'securerandom'

module ParkingInput
  VALID_SIZES = %w[small medium large].freeze

  module_function

  def normalize_plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  rescue StandardError
    nil
  end

  def normalize_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  rescue StandardError
    nil
  end

  def normalize_capacity(value)
    number =
      begin
        Integer(value)
      rescue StandardError
        begin
          value.to_i
        rescue StandardError
          0
        end
      end

    [number, 0].max
  end
end

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = ParkingInput.normalize_capacity(small)
    @medium = ParkingInput.normalize_capacity(medium)
    @large = ParkingInput.normalize_capacity(large)

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = ParkingInput.normalize_plate(license_plate_no)
    size = ParkingInput.normalize_size(car_size)

    return 'No space available' unless plate && size
    return 'No space available' if occupied_by?(plate)

    car = { plate: plate, size: size }

    case size
    when 'small'
      spot = first_available(:small, :medium, :large)
    when 'medium'
      spot = first_available(:medium, :large)
    when 'large'
      spot = first_available(:large)

      unless spot
        shuffle_large_car
        spot = first_available(:large)
      end
    end

    return 'No space available' unless spot

    place_car(car, spot)
    parking_status(car, spot.to_s)
  end

  def exit_car(license_plate_no)
    plate = ParkingInput.normalize_plate(license_plate_no)
    return 'Car not found' unless plate

    spot = nil
    car = nil

    @parking_spots.each do |spot_name, cars|
      found = cars.find { |candidate| candidate[:plate] == plate }
      if found
        spot = spot_name
        car = found
        break
      end
    end

    return 'Car not found' unless car

    @parking_spots[spot].delete(car)
    increase_available(spot)

    exit_status(car[:plate])
  end

  def shuffle_medium(car)
    return 'No space available' unless car.is_a?(Hash)

    victim = @parking_spots[:medium].first || @parking_spots[:large].first
    return 'No space available' unless victim && @small.positive?

    source = @parking_spots[:medium].include?(victim) ? :medium : :large
    move_car(victim, source, :small)
    place_car(car, source)

    parking_status(car, source.to_s)
  end

  def shuffle_large(car)
    return 'No space available' unless car.is_a?(Hash)

    return parking_status(car, :large.to_s) if @large.positive?

    return 'No space available' unless shuffle_large_car

    place_car(car, :large)
    parking_status(car, :large.to_s)
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : 'Car not found'
  end

  private

  def first_available(*spots)
    spots.find { |spot| available?(spot) }
  end

  def available?(spot)
    case spot
    when :small
      @small.positive?
    when :medium
      @medium.positive?
    when :large
      @large.positive?
    else
      false
    end
  end

  def place_car(car, spot)
    @parking_spots[spot] << car
    decrease_available(spot)
  end

  def move_car(car, from, to)
    return false unless @parking_spots[from].delete(car)

    increase_available(from)
    @parking_spots[to] << car
    decrease_available(to)
    true
  end

  def decrease_available(spot)
    case spot
    when :small
      @small -= 1 if @small.positive?
    when :medium
      @medium -= 1 if @medium.positive?
    when :large
      @large -= 1 if @large.positive?
    end
  end

  def increase_available(spot)
    case spot
    when :small
      @small += 1
    when :medium
      @medium += 1
    when :large
      @large += 1
    end
  end

  def occupied_by?(plate)
    @parking_spots.values.flatten.any? { |car| car[:plate] == plate }
  end

  def shuffle_large_car
    if @medium.positive?
      victim = @parking_spots[:large].find { |car| car[:size] == 'medium' }
      return move_car(victim, :large, :medium) if victim
    end

    if @small.positive?
      victim = @parking_spots[:large].find { |car| car[:size] == 'small' }
      return move_car(victim, :large, :small) if victim
    end

    if @medium.positive?
      victim = @parking_spots[:large].find { |car| car[:size] == 'small' }
      return move_car(victim, :large, :medium) if victim
    end

    false
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = ParkingInput.normalize_plate(license_plate) || ''
    @car_size = ParkingInput.normalize_size(car_size) || ''
    @entry_time = normalize_entry_time(entry_time)
  end

  def license
    @license_plate
  end

  def duration_hours
    duration = (Time.now - @entry_time) / 3600.0
    duration.negative? ? 0.0 : duration.to_f
  rescue StandardError
    0.0
  end

  def valid?
    duration_hours <= 24.0
  end

  def expired?
    !valid?
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
  end

  def normalize_entry_time(value)
    return value if value.is_a?(Time)

    Time.at(Float(value))
  rescue StandardError
    Time.now
  end
end

class ParkingFeeCalculator
  RATES = {
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }.freeze

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = ParkingInput.normalize_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 unless size && duration
    return 0.0 if duration <= 0.0 || duration <= GRACE_PERIOD_HOURS

    hours = duration.ceil
    fee = hours * RATES[size]

    [fee, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_duration(value)
    duration = Float(value)
    return nil unless duration.finite?
    return nil if duration.negative?

    duration
  rescue StandardError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **options)
    small_spots = options[:small_spots] if options.key?(:small_spots)
    medium_spots = options[:medium_spots] if options.key?(:medium_spots)
    large_spots = options[:large_spots] if options.key?(:large_spots)

    small_spots = options[:small] if options.key?(:small)
    medium_spots = options[:medium] if options.key?(:medium)
    large_spots = options[:large] if options.key?(:large)

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    normalized_plate = ParkingInput.normalize_plate(plate)
    normalized_size = ParkingInput.normalize_size(size)

    result = @garage.admit_car(normalized_plate, normalized_size)

    unless normalized_plate && normalized_size && result != 'No space available'
      return {
        success: false,
        message: result
      }
    end

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @tix_in_flight[normalized_plate] = ticket

    {
      success: true,
      message: result,
      ticket: ticket
    }
  end

  def exit_car(plate)
    normalized_plate = ParkingInput.normalize_plate(plate)
    ticket = normalized_plate && @tix_in_flight[normalized_plate]

    unless ticket
      return {
        success: false,
        message: 'No active ticket found'
      }
    end

    duration = ticket.duration_hours
    result = @garage.exit_car(normalized_plate)

    if result == 'Car not found'
      return {
        success: false,
        message: result
      }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    @tix_in_flight.delete(normalized_plate)

    {
      success: true,
      message: result,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    occupied = @garage.parking_spots.values.sum(&:size)
    available = @garage.small + @garage.medium + @garage.large

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: occupied,
      total_available: available
    }
  end

  def find_ticket(plate)
    normalized_plate = ParkingInput.normalize_plate(plate)
    normalized_plate && @tix_in_flight[normalized_plate]
  end
end