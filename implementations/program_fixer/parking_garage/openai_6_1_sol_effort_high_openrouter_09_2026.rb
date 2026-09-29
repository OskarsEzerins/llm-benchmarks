require 'securerandom'

module ParkingInput
  SIZES = %w[small medium large].freeze

  module_function

  def license_plate(value)
    value.to_s.strip
  end

  def car_size(value)
    value.to_s.strip.downcase
  end

  def valid_car_size?(value)
    SIZES.include?(car_size(value))
  end

  def capacity(value)
    [Integer(value), 0].max
  rescue ArgumentError, TypeError, RangeError
    0
  end
end

class ParkingGarage
  SPOT_TYPES = ParkingInput::SIZES
  SPOT_KEYS = {
    'small' => :small_spot,
    'medium' => :medium_spot,
    'large' => :large_spot
  }.freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = ParkingInput.capacity(small)
    @medium = ParkingInput.capacity(medium)
    @large = ParkingInput.capacity(large)

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = ParkingInput.license_plate(license_plate_no)
    size = ParkingInput.car_size(car_size)

    return 'Invalid license plate' if plate.empty?
    return 'Invalid car size' unless SPOT_TYPES.include?(size)
    return 'Car already parked' if parked?(plate)

    car = { plate: plate, size: size }
    preferences = allowed_spots(size)

    spot_type = preferences.find { |type| available_spots(type).positive? }
    spot_type ||= preferences.find { |type| make_space(type) }

    return parking_status unless spot_type

    @parking_spots[SPOT_KEYS.fetch(spot_type)] << car
    adjust_available(spot_type, -1)
    parking_status(car, spot_type)
  end

  def exit_car(license_plate_no)
    plate = ParkingInput.license_plate(license_plate_no)
    return 'Invalid license plate' if plate.empty?

    SPOT_TYPES.each do |spot_type|
      cars = @parking_spots[SPOT_KEYS.fetch(spot_type)]
      car = cars.find { |parked_car| parked_car[:plate] == plate }
      next unless car

      cars.delete(car)
      adjust_available(spot_type, 1)
      return exit_status(plate)
    end

    exit_status
  end

  def parked?(license_plate_no)
    plate = ParkingInput.license_plate(license_plate_no)
    return false if plate.empty?

    @parking_spots.values.any? do |cars|
      cars.any? { |car| car[:plate] == plate }
    end
  end

  def shuffle_medium(car)
    admit_shuffled_car(car, 'medium')
  end

  def shuffle_large(car)
    admit_shuffled_car(car, 'large')
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    return 'Car not found' if plate.nil?

    "car with license plate no. #{plate} exited"
  end

  private

  def allowed_spots(size)
    SPOT_TYPES.drop(SPOT_TYPES.index(size))
  end

  def available_spots(spot_type)
    case spot_type
    when 'small' then @small
    when 'medium' then @medium
    when 'large' then @large
    end
  end

  def adjust_available(spot_type, amount)
    case spot_type
    when 'small' then @small += amount
    when 'medium' then @medium += amount
    when 'large' then @large += amount
    end
  end

  def make_space(spot_type)
    return true if available_spots(spot_type).positive?

    source_index = SPOT_TYPES.index(spot_type)
    source = @parking_spots[SPOT_KEYS.fetch(spot_type)]

    source.each do |car|
      destinations = allowed_spots(car[:size]).select do |destination|
        SPOT_TYPES.index(destination) < source_index
      end

      destination = destinations.find do |type|
        available_spots(type).positive?
      end
      destination ||= destinations.find { |type| make_space(type) }
      next unless destination

      source.delete(car)
      @parking_spots[SPOT_KEYS.fetch(destination)] << car
      adjust_available(spot_type, 1)
      adjust_available(destination, -1)
      return true
    end

    false
  end

  def admit_shuffled_car(car, default_size)
    return parking_status unless car.is_a?(Hash)

    plate = car.fetch(:plate) do
      car.fetch(:license_plate_no) { car[:license_plate] }
    end
    size = car.fetch(:size) { car.fetch(:car_size, default_size) }

    admit_car(plate, size)
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :entry_time, :car_size

  alias_method :ticket_id, :id
  alias_method :license_plate_no, :license_plate
  alias_method :license, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = ParkingInput.license_plate(license_plate)
    @car_size = ParkingInput.car_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    return false if @license_plate.empty?
    return false unless ParkingInput.valid_car_size?(@car_size)

    elapsed_seconds = Time.now - @entry_time
    elapsed_seconds >= 0.0 && elapsed_seconds <= 24 * 3600
  end

  private

  def generate_ticket_id
    SecureRandom.uuid
  end
end

class ParkingFeeCalculator
  RATES = {
    small: 2.0,
    medium: 3.0,
    large: 5.0
  }.freeze

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = ParkingInput.car_size(car_size)
    return 0.0 unless ParkingInput.valid_car_size?(size)

    duration = Float(duration_hours)
    return 0.0 unless duration.finite?
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    total = duration.ceil * RATES.fetch(size.to_sym)
    [total, MAX_FEE.fetch(size)].min.to_f
  rescue ArgumentError, TypeError, RangeError
    0.0
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(small_spots = 0, medium_spots = 0, large_spots = 0, **options)
    small_spots = options.fetch(:small_spots, small_spots)
    medium_spots = options.fetch(:medium_spots, medium_spots)
    large_spots = options.fetch(:large_spots, large_spots)

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
    @tix_in_flight = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = ParkingInput.license_plate(plate)
    normalized_size = ParkingInput.car_size(size)

    if normalized_plate.empty?
      return { success: false, message: 'Invalid license plate' }
    end

    unless ParkingInput.valid_car_size?(normalized_size)
      return { success: false, message: 'Invalid car size' }
    end

    if @active_tickets.key?(normalized_plate)
      return { success: false, message: 'Car already parked' }
    end

    message = @garage.admit_car(normalized_plate, normalized_size)
    success = ParkingGarage::SPOT_TYPES.any? do |spot_type|
      message == "car with license plate no. #{normalized_plate} is parked at #{spot_type}"
    end

    return { success: false, message: message } unless success

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @active_tickets[normalized_plate] = ticket

    { success: true, message: message, ticket: ticket }
  end

  def exit_car(plate)
    normalized_plate = ParkingInput.license_plate(plate)

    if normalized_plate.empty?
      return { success: false, message: 'Invalid license plate' }
    end

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    unless message == "car with license plate no. #{normalized_plate} exited"
      return { success: false, message: message }
    end

    @active_tickets.delete(normalized_plate)

    {
      success: true,
      message: message,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.parking_spots.values.sum(&:size),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[ParkingInput.license_plate(plate)]
  end
end