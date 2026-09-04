require 'securerandom'

module ParkingInput
  CAR_SIZES = %w[small medium large].freeze

  def self.plate(value)
    value.to_s
  end

  def self.size(value)
    value.to_s.strip.downcase
  end

  def self.valid_plate?(value)
    !plate(value).strip.empty?
  end

  def self.valid_size?(value)
    CAR_SIZES.include?(size(value))
  end

  def self.capacity(value)
    [Integer(value), 0].max
  rescue ArgumentError, TypeError, RangeError
    0
  end
end

class ParkingGarage
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
    plate = ParkingInput.plate(license_plate_no)
    size = ParkingInput.size(car_size)

    return 'Invalid license plate' unless ParkingInput.valid_plate?(plate)
    return 'Invalid car size' unless ParkingInput.valid_size?(size)
    return 'Car is already parked' if parked?(plate)

    car = { plate: plate, size: size }

    COMPATIBLE_SPOTS.fetch(size).each do |spot_type|
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
    return 'Invalid license plate' unless ParkingInput.valid_plate?(plate)

    SPOT_KEYS.each do |spot_type, key|
      index = @parking_spots[key].index { |car| car[:plate] == plate }
      next unless index

      @parking_spots[key].delete_at(index)
      change_availability(spot_type, 1)
      return exit_status(plate)
    end

    exit_status
  end

  def parked?(license_plate_no)
    plate = ParkingInput.plate(license_plate_no)
    @parking_spots.values.any? do |cars|
      cars.any? { |car| car[:plate] == plate }
    end
  end

  def shuffle_medium(car)
    park_with_shuffle(car, 'medium')
  end

  def shuffle_large(car)
    park_with_shuffle(car, 'large')
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

  def available(spot_type)
    instance_variable_get("@#{spot_type}")
  end

  def change_availability(spot_type, amount)
    instance_variable_set("@#{spot_type}", available(spot_type) + amount)
  end

  def park(car, spot_type)
    @parking_spots.fetch(SPOT_KEYS.fetch(spot_type)) << car
    change_availability(spot_type, -1)
    parking_status(car, spot_type)
  end

  def park_with_shuffle(car, expected_size)
    return 'Invalid car' unless car.is_a?(Hash)

    plate = ParkingInput.plate(car[:plate])
    size = ParkingInput.size(car[:size])

    return 'Invalid license plate' unless ParkingInput.valid_plate?(plate)
    return 'Invalid car size' unless size == expected_size
    return 'Car is already parked' if parked?(plate)

    normalized_car = { plate: plate, size: size }

    COMPATIBLE_SPOTS.fetch(size).each do |spot_type|
      return park(normalized_car, spot_type) if available(spot_type).positive?
    end

    COMPATIBLE_SPOTS.fetch(size).each do |spot_type|
      return park(normalized_car, spot_type) if make_space(spot_type)
    end

    parking_status
  end

  # Relocations only move cars into smaller compatible spots.
  # Recursion supports chains such as small: medium -> small,
  # followed by medium: large -> medium.
  def make_space(spot_type)
    return true if available(spot_type).positive?

    source = @parking_spots.fetch(SPOT_KEYS.fetch(spot_type))
    source.each do |car|
      destinations = COMPATIBLE_SPOTS.fetch(car[:size])
                                    .take_while { |type| type != spot_type }

      destination = destinations.find { |type| available(type).positive? }
      destination ||= destinations.find { |type| make_space(type) }
      next unless destination

      source.delete(car)
      change_availability(spot_type, 1)

      @parking_spots.fetch(SPOT_KEYS.fetch(destination)) << car
      change_availability(destination, -1)
      return true
    end

    false
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :entry_time, :car_size

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

  def valid?
    now = Time.now
    ParkingInput.valid_plate?(@license_plate) &&
      ParkingInput.valid_size?(@car_size) &&
      now >= @entry_time &&
      duration_hours(now) <= 24.0
  end

  private

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
    size = ParkingInput.size(car_size)
    return 0.0 unless RATES.key?(size)

    duration = Float(duration_hours)
    return 0.0 unless duration.finite? && duration.positive?
    return 0.0 if duration <= GRACE_PERIOD_HOURS

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
    plate = ParkingInput.plate(plate)
    size = ParkingInput.size(size)

    unless ParkingInput.valid_plate?(plate)
      return { success: false, message: 'Invalid license plate' }
    end

    unless ParkingInput.valid_size?(size)
      return { success: false, message: 'Invalid car size' }
    end

    if @active_tickets.key?(plate) || @garage.parked?(plate)
      return { success: false, message: 'Car is already parked' }
    end

    message = @garage.admit_car(plate, size)
    unless @garage.parked?(plate)
      return { success: false, message: message }
    end

    ticket = ParkingTicket.new(plate, size)
    @active_tickets[plate] = ticket

    { success: true, message: message, ticket: ticket }
  end

  def exit_car(plate)
    plate = ParkingInput.plate(plate)

    unless ParkingInput.valid_plate?(plate)
      return { success: false, message: 'Invalid license plate' }
    end

    ticket = @active_tickets[plate]
    unless ticket
      return { success: false, message: 'Ticket not found' }
    end

    unless @garage.parked?(plate)
      return { success: false, message: 'Car not found' }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(plate)
    @active_tickets.delete(plate)

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
      total_occupied: @garage.parking_spots.values.sum(&:length),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[ParkingInput.plate(plate)]
  end
end