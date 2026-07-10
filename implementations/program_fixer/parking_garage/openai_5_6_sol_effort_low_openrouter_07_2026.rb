require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze
  SPOT_KEYS = {
    small: :tiny_spot,
    medium: :mid_spot,
    large: :grande_spot
  }.freeze
  COMPATIBLE_SPOTS = {
    small: %i[small medium large],
    medium: %i[medium large],
    large: %i[large]
  }.freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = normalize_capacity(small)
    @medium = normalize_capacity(medium)
    @large = normalize_capacity(large)

    @parking_spots = {
      tiny_spot: [],
      mid_spot: [],
      grande_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)

    return parking_status unless plate && size

    car = { plate: plate, size: size }

    COMPATIBLE_SPOTS[size.to_sym].each do |spot_type|
      next unless available_for?(spot_type)

      park_car(car, spot_type)
      return parking_status(car, spot_type.to_s)
    end

    if size == 'medium'
      COMPATIBLE_SPOTS[:medium].each do |spot_type|
        next unless ensure_available(spot_type)

        park_car(car, spot_type)
        return parking_status(car, spot_type.to_s)
      end
    elsif size == 'large' && ensure_available(:large)
      park_car(car, :large)
      return parking_status(car, 'large')
    end

    parking_status
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status unless plate

    SPOT_KEYS.each do |spot_type, key|
      car = @parking_spots[key].find { |parked_car| parked_car[:plate] == plate }
      next unless car

      @parking_spots[key].delete(car)
      increment_available(spot_type)
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    size = normalize_size(car && car[:size])
    return parking_status unless size == 'medium'

    COMPATIBLE_SPOTS[:medium].each do |spot_type|
      next unless ensure_available(spot_type)

      park_car(car, spot_type)
      return parking_status(car, spot_type.to_s)
    end

    parking_status
  end

  def shuffle_large(car)
    size = normalize_size(car && car[:size])
    return parking_status unless size == 'large'
    return parking_status unless ensure_available(:large)

    park_car(car, :large)
    parking_status(car, 'large')
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      'Car not found'
    end
  end

  private

  def normalize_capacity(value)
    capacity = Integer(value)
    capacity.negative? ? 0 : capacity
  rescue ArgumentError, TypeError
    0
  end

  def normalize_plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  end

  def normalize_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  end

  def available_for?(spot_type)
    public_send(spot_type).positive?
  end

  def park_car(car, spot_type)
    normalized_car = {
      plate: car[:plate].to_s,
      size: car[:size].to_s.downcase
    }

    @parking_spots[SPOT_KEYS.fetch(spot_type)] << normalized_car
    decrement_available(spot_type)
  end

  def move_car(car, from_spot, to_spot)
    @parking_spots[SPOT_KEYS.fetch(from_spot)].delete(car)
    increment_available(from_spot)

    @parking_spots[SPOT_KEYS.fetch(to_spot)] << car
    decrement_available(to_spot)
  end

  def ensure_available(spot_type, visited = [])
    return true if available_for?(spot_type)
    return false if visited.include?(spot_type)

    next_visited = visited + [spot_type]
    occupants = @parking_spots[SPOT_KEYS.fetch(spot_type)]

    occupants.dup.each do |occupant|
      occupant_size = normalize_size(occupant[:size])
      next unless occupant_size

      destinations = COMPATIBLE_SPOTS.fetch(occupant_size.to_sym) - [spot_type]

      destinations.each do |destination|
        next if next_visited.include?(destination)
        next unless ensure_available(destination, next_visited)

        move_car(occupant, spot_type, destination)
        return true
      end
    end

    false
  end

  def decrement_available(spot_type)
    case spot_type
    when :small
      @small -= 1
    when :medium
      @medium -= 1
    when :large
      @large -= 1
    end
  end

  def increment_available(spot_type)
    case spot_type
    when :small
      @small += 1
    when :medium
      @medium += 1
    when :large
      @large += 1
    end
  end
end

class ParkingTicket
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :id, :entry_time, :car_size, :license_plate

  alias license_plate_no license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size = normalize_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours(current_time = Time.now)
    return 0.0 unless current_time.is_a?(Time)

    duration = (current_time - @entry_time) / 3600.0
    duration.negative? ? 0.0 : duration
  end

  def valid?(current_time = Time.now)
    duration_hours(current_time) <= 24.0
  end

  private

  def normalize_size(value)
    size = value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : ''
  end

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
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
    size = normalize_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 unless size && duration
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    total = duration.ceil * RATES.fetch(size)
    [total, MAX_FEE.fetch(size)].min.to_f
  end

  private

  def normalize_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    RATES.key?(size) ? size : nil
  end

  def normalize_duration(value)
    duration = Float(value)
    return nil unless duration.finite?
    return nil if duration.negative?

    duration
  rescue ArgumentError, TypeError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **options)
    small_spots = options[:small_spots] if options.key?(:small_spots)
    medium_spots = options[:medium_spots] if options.key?(:medium_spots)
    large_spots = options[:large_spots] if options.key?(:large_spots)

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
    @tix_in_flight = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    unless normalized_plate && normalized_size
      return { success: false, message: 'No space available' }
    end

    if @active_tickets.key?(normalized_plate)
      return { success: false, message: 'Car is already parked' }
    end

    result = @garage.admit_car(normalized_plate, normalized_size)

    unless result.include?('is parked at')
      return { success: false, message: result }
    end

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @active_tickets[normalized_plate] = ticket

    {
      success: true,
      message: result,
      ticket: ticket
    }
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    ticket = normalized_plate && @active_tickets[normalized_plate]

    unless ticket
      return {
        success: false,
        message: 'Car not found',
        fee: 0.0,
        duration_hours: 0.0
      }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(normalized_plate)

    if result == 'Car not found'
      return {
        success: false,
        message: result,
        fee: 0.0,
        duration_hours: duration
      }
    end

    @active_tickets.delete(normalized_plate)

    {
      success: true,
      message: result,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @active_tickets.size,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    normalized_plate = normalize_plate(plate)
    normalized_plate ? @active_tickets[normalized_plate] : nil
  end

  private

  def normalize_plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  end

  def normalize_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    %w[small medium large].include?(size) ? size : nil
  end
end