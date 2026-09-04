require 'securerandom'

class ParkingGarage
  SIZES = %w[small medium large].freeze
  SPOT_KEYS = {
    'small' => :small_spot,
    'medium' => :medium_spot,
    'large' => :large_spot
  }.freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = normalize_capacity(small)
    @medium = normalize_capacity(medium)
    @large = normalize_capacity(large)

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.strip.downcase

    return 'Invalid license plate' if plate.empty?
    return 'Invalid car size' unless SIZES.include?(size)

    if parked?(plate)
      return "car with license plate no. #{plate} is already parked"
    end

    car = { plate: plate, size: size }
    eligible_spots = SIZES.drop(SIZES.index(size))
    available_spot = eligible_spots.find { |spot| available_count(spot).positive? }

    return park_car(car, available_spot) if available_spot

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
    plate = license_plate_no.to_s.strip
    return 'Invalid license plate' if plate.empty?

    SIZES.each do |spot_type|
      cars = @parking_spots.fetch(SPOT_KEYS.fetch(spot_type))
      index = cars.index { |car| car[:plate] == plate }
      next unless index

      cars.delete_at(index)
      change_available_count(spot_type, 1)
      return exit_status(plate)
    end

    exit_status
  end

  def parked?(license_plate_no)
    plate = license_plate_no.to_s.strip
    return false if plate.empty?

    @parking_spots.values.any? do |cars|
      cars.any? { |car| car[:plate] == plate }
    end
  end

  def shuffle_medium(car)
    park_with_shuffle(car, %w[medium large])
  end

  def shuffle_large(car)
    park_with_shuffle(car, ['large'])
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    if plate.nil?
      'Car not found'
    else
      "car with license plate no. #{plate} exited"
    end
  end

  private

  def normalize_capacity(value)
    [Integer(value), 0].max
  rescue ArgumentError, TypeError, RangeError
    0
  end

  def available_count(spot_type)
    case spot_type
    when 'small' then @small
    when 'medium' then @medium
    when 'large' then @large
    end
  end

  def change_available_count(spot_type, amount)
    case spot_type
    when 'small' then @small += amount
    when 'medium' then @medium += amount
    when 'large' then @large += amount
    end
  end

  def park_car(car, spot_type)
    @parking_spots.fetch(SPOT_KEYS.fetch(spot_type)) << car
    change_available_count(spot_type, -1)
    parking_status(car, spot_type)
  end

  def move_car(car, from, to)
    @parking_spots.fetch(SPOT_KEYS.fetch(from)).delete(car)
    @parking_spots.fetch(SPOT_KEYS.fetch(to)) << car

    change_available_count(from, 1)
    change_available_count(to, -1)
  end

  def park_with_shuffle(car, eligible_spots)
    eligible_spots.each do |spot_type|
      return park_car(car, spot_type) if make_space(spot_type)
    end

    parking_status
  end

  # Recursively relocate cars into smaller compatible spots. Changes are
  # committed only when a complete relocation path has been found.
  def make_space(spot_type)
    return true if available_count(spot_type).positive?

    spot_index = SIZES.index(spot_type)
    return false if spot_index.zero?

    @parking_spots.fetch(SPOT_KEYS.fetch(spot_type)).each do |car|
      car_index = SIZES.index(car[:size])
      next unless car_index && car_index < spot_index

      SIZES[car_index...spot_index].each do |destination|
        next unless make_space(destination)

        move_car(car, spot_type, destination)
        return true
      end
    end

    false
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :entry_time, :car_size

  alias_method :ticket_id, :id
  alias_method :license_plate_no, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time
  end

  def duration_hours
    return 0.0 unless @entry_time.is_a?(Time)

    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    return false if @license_plate.empty?
    return false unless ParkingGarage::SIZES.include?(@car_size)
    return false unless @entry_time.is_a?(Time)

    duration_hours.between?(0.0, 24.0)
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
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    duration = Float(duration_hours)
    return 0.0 unless duration.finite?
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    total = duration.ceil * RATES.fetch(size)
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
  end

  def admit_car(plate, size)
    normalized_plate = plate.to_s.strip
    normalized_size = size.to_s.strip.downcase

    if normalized_plate.empty?
      return { success: false, message: 'Invalid license plate' }
    end

    unless ParkingGarage::SIZES.include?(normalized_size)
      return { success: false, message: 'Invalid car size' }
    end

    if @active_tickets.key?(normalized_plate)
      return {
        success: false,
        message: "car with license plate no. #{normalized_plate} is already parked"
      }
    end

    message = @garage.admit_car(normalized_plate, normalized_size)

    success = ParkingGarage::SIZES.any? do |spot_type|
      message == "car with license plate no. #{normalized_plate} is parked at #{spot_type}"
    end

    return { success: false, message: message } unless success

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @active_tickets[normalized_plate] = ticket

    { success: true, message: message, ticket: ticket }
  end

  def exit_car(plate)
    normalized_plate = plate.to_s.strip

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
      total_occupied: @garage.parking_spots.values.inject(0) { |sum, cars| sum + cars.size },
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end