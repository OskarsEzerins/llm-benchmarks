require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

  SPOT_KEYS = {
    small: :small_spot,
    medium: :medium_spot,
    large: :large_spot
  }.freeze

  SIZE_RANK = {
    'small' => 1,
    'medium' => 2,
    'large' => 3
  }.freeze

  PREFERENCES = {
    'small' => %i[small medium large],
    'medium' => %i[medium large],
    'large' => %i[large]
  }.freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @capacities = {
      small: normalize_capacity(small),
      medium: normalize_capacity(medium),
      large: normalize_capacity(large)
    }

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }

    sync_availability!
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)

    return parking_status if plate.nil? || size.nil?
    return "car with license plate no. #{plate} is already parked" if parked?(plate)

    car = { plate: plate, size: size }

    preferred_spot = PREFERENCES[size].find do |spot_type|
      available_for?(spot_type)
    end

    if preferred_spot
      park_in_spot(car, preferred_spot)
      return parking_status(car, preferred_spot)
    end

    shuffled_spot = allocate_with_repacking(car)
    shuffled_spot ? parking_status(car, shuffled_spot) : parking_status
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status if plate.nil?

    @parking_spots.each_value do |cars|
      car = cars.find { |parked_car| parked_car[:plate] == plate }
      next unless car

      cars.delete(car)
      sync_availability!
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    normalized_car = normalize_car(car, 'medium')
    return parking_status unless normalized_car

    spot = allocate_with_repacking(normalized_car)
    spot ? parking_status(normalized_car, spot) : parking_status
  end

  def shuffle_large(car)
    normalized_car = normalize_car(car, 'large')
    return parking_status unless normalized_car

    spot = allocate_with_repacking(normalized_car)
    spot ? parking_status(normalized_car, spot) : parking_status
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    plate = car[:plate] || car[:license_plate_no]
    spot_type = space.to_s.sub(/_spot\z/, '')

    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def exit_status(plate = nil)
    return 'Car not found' if plate.nil?

    "car with license plate no. #{plate} exited"
  end

  def occupied_count
    @parking_spots.values.sum(&:length)
  end

  def available_count
    @small + @medium + @large
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

  def normalize_car(car, expected_size)
    return nil unless car.is_a?(Hash)

    plate = normalize_plate(car[:plate] || car[:license_plate_no])
    size = normalize_size(car[:size] || car[:car_size] || expected_size)

    return nil if plate.nil? || size != expected_size

    { plate: plate, size: size }
  end

  def parked?(plate)
    @parking_spots.values.any? do |cars|
      cars.any? { |car| car[:plate] == plate }
    end
  end

  def available_for?(spot_type)
    @parking_spots.fetch(SPOT_KEYS.fetch(spot_type)).length <
      @capacities.fetch(spot_type)
  end

  def park_in_spot(car, spot_type)
    @parking_spots.fetch(SPOT_KEYS.fetch(spot_type)) << car
    sync_availability!
  end

  def allocate_with_repacking(incoming_car)
    all_cars = @parking_spots.values.flatten + [incoming_car]
    return nil if all_cars.length > @capacities.values.sum

    assignments = {
      small: [],
      medium: [],
      large: []
    }

    sorted_cars = all_cars.sort_by do |car|
      -SIZE_RANK.fetch(car[:size], 0)
    end

    sorted_cars.each do |car|
      preferences = PREFERENCES[car[:size]]
      return nil unless preferences

      spot_type = preferences.find do |candidate|
        assignments[candidate].length < @capacities[candidate]
      end
      return nil unless spot_type

      assignments[spot_type] << car
    end

    incoming_spot = assignments.find do |_spot_type, cars|
      cars.any? { |car| car.equal?(incoming_car) }
    end&.first
    return nil unless incoming_spot

    assignments.each do |spot_type, cars|
      @parking_spots[SPOT_KEYS[spot_type]].replace(cars)
    end

    sync_availability!
    incoming_spot
  end

  def sync_availability!
    @small = @capacities[:small] - @parking_spots[:small_spot].length
    @medium = @capacities[:medium] - @parking_spots[:medium_spot].length
    @large = @capacities[:large] - @parking_spots[:large_spot].length
  end
end

class ParkingTicket
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = normalize_plate(license_plate)
    @car_size = normalize_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def license_plate_no
    @license_plate
  end

  def license
    @license_plate
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

  def normalize_plate(value)
    return '' if value.nil?

    value.to_s.strip
  rescue StandardError
    ''
  end

  def normalize_size(value)
    return '' if value.nil?

    size = value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : ''
  rescue StandardError
    ''
  end

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
    size = normalize_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 if size.nil? || duration.nil?
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    total = duration.ceil * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    RATES.key?(size) ? size : nil
  rescue StandardError
    nil
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
    small_spots = options[:small_spots] if small_spots.nil?
    medium_spots = options[:medium_spots] if medium_spots.nil?
    large_spots = options[:large_spots] if large_spots.nil?

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    if normalized_plate.nil? || normalized_size.nil?
      return { success: false, message: 'No space available' }
    end

    if @active_tickets.key?(normalized_plate)
      return {
        success: false,
        message: "car with license plate no. #{normalized_plate} is already parked"
      }
    end

    message = @garage.admit_car(normalized_plate, normalized_size)

    unless message.start_with?(
      "car with license plate no. #{normalized_plate} is parked at "
    )
      return { success: false, message: message }
    end

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @active_tickets[normalized_plate] = ticket

    {
      success: true,
      message: message,
      ticket: ticket
    }
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    ticket = normalized_plate && @active_tickets[normalized_plate]

    unless ticket
      display_plate = normalized_plate || ''
      return {
        success: false,
        message: "No active ticket found for license plate no. #{display_plate}"
      }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    if message == 'Car not found'
      return { success: false, message: message }
    end

    @active_tickets.delete(normalized_plate)

    {
      success: true,
      message: message,
      fee: fee.to_f,
      duration_hours: duration.to_f
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.occupied_count,
      total_available: @garage.available_count
    }
  end

  def find_ticket(plate)
    normalized_plate = normalize_plate(plate)
    return nil if normalized_plate.nil?

    @active_tickets[normalized_plate]
  end

  private

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
    ParkingGarage::VALID_SIZES.include?(size) ? size : nil
  rescue StandardError
    nil
  end
end