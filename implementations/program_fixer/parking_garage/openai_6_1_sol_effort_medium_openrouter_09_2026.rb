require 'securerandom'

module ParkingInput
  SIZES = %w[small medium large].freeze

  def self.plate(value)
    value.to_s.strip
  end

  def self.size(value)
    value.to_s.strip.downcase
  end

  def self.capacity(value)
    [Integer(value), 0].max
  rescue ArgumentError, TypeError, RangeError
    0
  end
end

class ParkingGarage
  attr_reader :parking_spots

  SPOT_KEYS = {
    'small' => :small_spot,
    'medium' => :medium_spot,
    'large' => :large_spot
  }.freeze

  COMPATIBLE_SPOTS = {
    'small' => %w[small medium large].freeze,
    'medium' => %w[medium large].freeze,
    'large' => %w[large].freeze
  }.freeze

  def initialize(small, medium, large)
    @capacities = {
      'small' => ParkingInput.capacity(small),
      'medium' => ParkingInput.capacity(medium),
      'large' => ParkingInput.capacity(large)
    }

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def small
    available('small')
  end

  def medium
    available('medium')
  end

  def large
    available('large')
  end

  def admit_car(license_plate_no, car_size)
    plate = ParkingInput.plate(license_plate_no)
    size = ParkingInput.size(car_size)

    return 'Invalid license plate' if plate.empty?
    return 'Invalid car size' unless COMPATIBLE_SPOTS.key?(size)
    return 'Car is already parked' if parked?(plate)

    car = { plate: plate, size: size }

    # Prefer an available spot before moving any existing cars.
    spot = COMPATIBLE_SPOTS[size].find { |type| available(type).positive? }
    return park(car, spot) if spot

    COMPATIBLE_SPOTS[size].each do |type|
      return park(car, type) if make_space(type)
    end

    parking_status
  end

  def exit_car(license_plate_no)
    plate = ParkingInput.plate(license_plate_no)
    return 'Invalid license plate' if plate.empty?

    @parking_spots.each_value do |cars|
      car = cars.find { |parked_car| parked_car[:plate] == plate }
      next unless car

      cars.delete(car)
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    shuffle_car(car, 'medium')
  end

  def shuffle_large(car)
    shuffle_car(car, 'large')
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

  def available(type)
    @capacities.fetch(type) - @parking_spots.fetch(SPOT_KEYS.fetch(type)).length
  end

  def parked?(plate)
    @parking_spots.values.any? do |cars|
      cars.any? { |car| car[:plate] == plate }
    end
  end

  def park(car, type)
    @parking_spots.fetch(SPOT_KEYS.fetch(type)) << car
    parking_status(car, type)
  end

  # Moves cars only into smaller compatible spots. This also supports
  # moving a small car out of medium before moving a medium out of large.
  def make_space(type)
    return true if available(type).positive?

    source = @parking_spots.fetch(SPOT_KEYS.fetch(type))
    current_rank = ParkingInput::SIZES.index(type)

    source.dup.each do |car|
      targets = COMPATIBLE_SPOTS.fetch(car[:size]).select do |target|
        ParkingInput::SIZES.index(target) < current_rank
      end

      targets.each do |target|
        next unless make_space(target)

        source.delete(car)
        @parking_spots.fetch(SPOT_KEYS.fetch(target)) << car
        return true
      end
    end

    false
  end

  def shuffle_car(car, expected_size)
    return 'Invalid license plate' unless car.is_a?(Hash)

    plate = ParkingInput.plate(car[:plate])
    size = ParkingInput.size(car[:size])

    return 'Invalid license plate' if plate.empty?
    return 'Invalid car size' unless size == expected_size
    return 'Car is already parked' if parked?(plate)

    normalized_car = { plate: plate, size: size }
    COMPATIBLE_SPOTS.fetch(size).each do |type|
      return park(normalized_car, type) if make_space(type)
    end

    parking_status
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :entry_time, :car_size

  alias ticket_id id
  alias license_plate_no license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = ParkingInput.plate(license_plate)
    @car_size = ParkingInput.size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    elapsed = Time.now - @entry_time
    !@license_plate.empty? &&
      ParkingInput::SIZES.include?(@car_size) &&
      elapsed >= 0.0 &&
      elapsed < 24 * 3600
  end

  private

  def generate_ticket_id
    SecureRandom.uuid
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
    size = ParkingInput.size(car_size)
    return 0.0 unless RATES.key?(size)
    return 0.0 unless duration_hours.is_a?(Numeric) ||
                      duration_hours.is_a?(String)

    duration = Float(duration_hours)
    return 0.0 unless duration.finite? && duration >= 0.0
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    [duration.ceil * RATES.fetch(size), MAX_FEE.fetch(size)].min.to_f
  rescue ArgumentError, TypeError, RangeError
    0.0
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **options)
    small_spots = options.fetch(:small_spots, small_spots)
    medium_spots = options.fetch(:medium_spots, medium_spots)
    large_spots = options.fetch(:large_spots, large_spots)

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = ParkingInput.plate(plate)
    normalized_size = ParkingInput.size(size)

    if normalized_plate.empty?
      return { success: false, message: 'Invalid license plate' }
    end

    unless ParkingInput::SIZES.include?(normalized_size)
      return { success: false, message: 'Invalid car size' }
    end

    if @active_tickets.key?(normalized_plate)
      return { success: false, message: 'Car is already parked' }
    end

    message = @garage.admit_car(normalized_plate, normalized_size)
    unless message.start_with?("car with license plate no. #{normalized_plate} is parked at ")
      return { success: false, message: message }
    end

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @active_tickets[normalized_plate] = ticket

    { success: true, message: message, ticket: ticket }
  end

  def exit_car(plate)
    normalized_plate = ParkingInput.plate(plate)

    if normalized_plate.empty?
      return { success: false, message: 'Invalid license plate' }
    end

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'Car not found' } unless ticket

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
    small_available = @garage.small
    medium_available = @garage.medium
    large_available = @garage.large

    {
      small_available: small_available,
      medium_available: medium_available,
      large_available: large_available,
      total_occupied: @garage.parking_spots.values.sum(&:length),
      total_available: small_available + medium_available + large_available
    }
  end

  def find_ticket(plate)
    @active_tickets[ParkingInput.plate(plate)]
  end
end