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
  attr_reader :parking_spots, :small, :medium, :large

  SPOT_KEYS = {
    'small' => :small_spot,
    'medium' => :medium_spot,
    'large' => :large_spot
  }.freeze

  PREFERENCES = {
    'small' => %w[small medium large].freeze,
    'medium' => %w[medium large].freeze,
    'large' => %w[large].freeze
  }.freeze

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
    plate = ParkingInput.plate(license_plate_no)
    size = ParkingInput.size(car_size)

    return 'Invalid license plate' if plate.empty?
    return 'Invalid car size' unless ParkingInput::SIZES.include?(size)
    return 'Car already parked' if parked_car(plate)

    car = { plate: plate, size: size }

    PREFERENCES.fetch(size).each do |spot_type|
      return park(car, spot_type) if available(spot_type).positive?
    end

    case size
    when 'medium'
      shuffle_medium(car)
    when 'large'
      shuffle_large(car)
    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = ParkingInput.plate(license_plate_no)
    return 'Invalid license plate' if plate.empty?

    SPOT_KEYS.each do |spot_type, key|
      car = @parking_spots[key].find { |parked| parked[:plate] == plate }
      next unless car

      @parking_spots[key].delete(car)
      adjust_available(spot_type, 1)
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    %w[medium large].each do |spot_type|
      return park(car, spot_type) if make_available(spot_type)
    end
    parking_status
  end

  def shuffle_large(car)
    return park(car, 'large') if make_available('large')

    parking_status
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

  def parked_car(plate)
    @parking_spots.values.any? do |cars|
      cars.any? { |car| car[:plate] == plate }
    end
  end

  def available(spot_type)
    instance_variable_get("@#{spot_type}")
  end

  def adjust_available(spot_type, amount)
    instance_variable_set("@#{spot_type}", available(spot_type) + amount)
  end

  def park(car, spot_type)
    @parking_spots.fetch(SPOT_KEYS.fetch(spot_type)) << car
    adjust_available(spot_type, -1)
    parking_status(car, spot_type)
  end

  def move_car(car, from, to)
    @parking_spots.fetch(SPOT_KEYS.fetch(from)).delete(car)
    @parking_spots.fetch(SPOT_KEYS.fetch(to)) << car
    adjust_available(from, 1)
    adjust_available(to, -1)
  end

  # Move cars only into smaller, compatible spots. Recursion permits
  # a small car to free a medium spot for a medium car in a large spot.
  def make_available(spot_type)
    return true if available(spot_type).positive?

    source_index = ParkingInput::SIZES.index(spot_type)
    return false if source_index.zero?

    @parking_spots.fetch(SPOT_KEYS.fetch(spot_type)).dup.each do |car|
      car_index = ParkingInput::SIZES.index(car[:size])
      next unless car_index && car_index < source_index

      ParkingInput::SIZES[car_index...source_index].each do |destination|
        next unless make_available(destination)

        move_car(car, spot_type, destination)
        return true
      end
    end

    false
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

  def duration_hours(now = Time.now)
    [(now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?(now = Time.now)
    elapsed = now - @entry_time
    elapsed >= 0 && elapsed < 24 * 3600
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = ParkingInput.size(car_size)
    return 0.0 unless RATES.key?(size)

    duration = Float(duration_hours)
    return 0.0 unless duration.finite? && duration > GRACE_PERIOD

    [duration.ceil * RATES.fetch(size), MAX_FEE.fetch(size)].min.to_f
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
  end

  def admit_car(plate, size)
    normalized_plate = ParkingInput.plate(plate)
    normalized_size = ParkingInput.size(size)

    return { success: false, message: 'Invalid license plate' } if normalized_plate.empty?
    unless ParkingInput::SIZES.include?(normalized_size)
      return { success: false, message: 'Invalid car size' }
    end
    if @active_tickets.key?(normalized_plate)
      return { success: false, message: 'Car already parked' }
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
    return { success: false, message: 'Invalid license plate' } if normalized_plate.empty?

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
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.parking_spots.values.sum(&:size),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[ParkingInput.plate(plate)]
  end
end