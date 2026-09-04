require 'securerandom'

module ParkingInputNormalization
  CAR_SIZES = %w[small medium large].freeze

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

  def initialize(small, medium, large)
    @small = ParkingInputNormalization.capacity(small)
    @medium = ParkingInputNormalization.capacity(medium)
    @large = ParkingInputNormalization.capacity(large)

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = ParkingInputNormalization.plate(license_plate_no)
    size = ParkingInputNormalization.size(car_size)

    return 'Invalid license plate' if plate.empty?
    return 'Invalid car size' unless ParkingInputNormalization::CAR_SIZES.include?(size)

    if parked?(plate)
      return "car with license plate no. #{plate} is already parked"
    end

    car = { plate: plate, size: size }
    eligible_spots = eligible_sizes(size)

    # Prefer an available spot before moving any existing cars.
    eligible_spots.each do |spot_size|
      return park(car, spot_size) if available(spot_size).positive?
    end

    eligible_spots.each do |spot_size|
      return park(car, spot_size) if free_spot(spot_size)
    end

    parking_status
  end

  def exit_car(license_plate_no)
    plate = ParkingInputNormalization.plate(license_plate_no)
    return 'Invalid license plate' if plate.empty?

    SPOT_KEYS.each do |size, key|
      car = @parking_spots[key].find { |parked_car| parked_car[:plate] == plate }
      next unless car

      @parking_spots[key].delete(car)
      change_available(size, 1)
      return exit_status(plate)
    end

    exit_status
  end

  def parked?(license_plate_no)
    plate = ParkingInputNormalization.plate(license_plate_no)
    @parking_spots.values.any? do |cars|
      cars.any? { |car| car[:plate] == plate }
    end
  end

  def shuffle_medium(car)
    return 'Invalid car' unless car.is_a?(Hash)

    admit_car(car[:plate], 'medium')
  end

  def shuffle_large(car)
    return 'Invalid car' unless car.is_a?(Hash)

    admit_car(car[:plate], 'large')
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

  def eligible_sizes(car_size)
    sizes = ParkingInputNormalization::CAR_SIZES
    sizes.drop(sizes.index(car_size))
  end

  def available(size)
    case size
    when 'small' then @small
    when 'medium' then @medium
    when 'large' then @large
    end
  end

  def change_available(size, amount)
    case size
    when 'small' then @small += amount
    when 'medium' then @medium += amount
    when 'large' then @large += amount
    end
  end

  def park(car, spot_size)
    @parking_spots.fetch(SPOT_KEYS.fetch(spot_size)) << car
    change_available(spot_size, -1)
    parking_status(car, spot_size)
  end

  # Only move cars into smaller spots that still accommodate their size.
  # Recursion supports chains such as small: medium -> small,
  # followed by medium: large -> medium.
  def free_spot(spot_size)
    return true if available(spot_size).positive?

    sizes = ParkingInputNormalization::CAR_SIZES
    source_index = sizes.index(spot_size)
    source = @parking_spots.fetch(SPOT_KEYS.fetch(spot_size))

    source.each do |car|
      minimum_index = sizes.index(car[:size])
      next unless minimum_index && minimum_index < source_index

      sizes[minimum_index...source_index].each do |destination_size|
        next unless free_spot(destination_size)

        source.delete(car)
        change_available(spot_size, 1)

        destination = @parking_spots.fetch(SPOT_KEYS.fetch(destination_size))
        destination << car
        change_available(destination_size, -1)
        return true
      end
    end

    false
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :entry_time, :car_size

  alias license_plate_no license_plate
  alias license license_plate
  alias ticket_id id

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = ParkingInputNormalization.plate(license_plate)
    @car_size = ParkingInputNormalization.size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    return false if @license_plate.empty?
    return false unless ParkingInputNormalization::CAR_SIZES.include?(@car_size)

    elapsed_seconds = Time.now - @entry_time
    elapsed_seconds >= 0 && elapsed_seconds <= 24 * 3600
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
    size = ParkingInputNormalization.size(car_size)
    return 0.0 unless RATES.key?(size)

    duration = Float(duration_hours)
    return 0.0 unless duration.finite? && duration >= 0.0
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
    @tix_in_flight = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = ParkingInputNormalization.plate(plate)
    normalized_size = ParkingInputNormalization.size(size)

    if normalized_plate.empty?
      return { success: false, message: 'Invalid license plate' }
    end

    unless ParkingInputNormalization::CAR_SIZES.include?(normalized_size)
      return { success: false, message: 'Invalid car size' }
    end

    if @active_tickets.key?(normalized_plate) || @garage.parked?(normalized_plate)
      return {
        success: false,
        message: "car with license plate no. #{normalized_plate} is already parked"
      }
    end

    message = @garage.admit_car(normalized_plate, normalized_size)

    unless @garage.parked?(normalized_plate)
      return { success: false, message: message }
    end

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @active_tickets[normalized_plate] = ticket

    { success: true, message: message, ticket: ticket }
  end

  def exit_car(plate)
    normalized_plate = ParkingInputNormalization.plate(plate)

    if normalized_plate.empty?
      return { success: false, message: 'Invalid license plate' }
    end

    ticket = @active_tickets[normalized_plate]
    unless ticket
      return { success: false, message: 'Ticket not found' }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    unless message == @garage.exit_status(normalized_plate)
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
      total_occupied: @garage.parking_spots.values.reduce(0) { |sum, cars| sum + cars.length },
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[ParkingInputNormalization.plate(plate)]
  end
end