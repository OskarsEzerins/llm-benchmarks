require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large,
              :total_small, :total_medium, :total_large

  VALID_SIZES = %w[small medium large].freeze

  SPOT_KEYS = {
    'small' => :small_spot,
    'medium' => :medium_spot,
    'large' => :large_spot
  }.freeze

  SPOT_TYPES = SPOT_KEYS.invert.freeze

  PREFERENCES = {
    'small' => %w[small medium large],
    'medium' => %w[medium large],
    'large' => %w[large]
  }.freeze

  PRIORITY = {
    'large' => 0,
    'medium' => 1,
    'small' => 2
  }.freeze

  def initialize(small, medium, large)
    @total_small = normalize_capacity(small)
    @total_medium = normalize_capacity(medium)
    @total_large = normalize_capacity(large)
    reset_parking_spots
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_license_plate(license_plate_no)
    size = normalize_car_size(car_size)

    return parking_status unless plate && size
    return parking_status if parked?(plate)

    car = build_car(plate, size)
    direct_spot = PREFERENCES[size].find { |spot_type| available_count(spot_type).positive? }

    if direct_spot
      park_car(car, direct_spot)
      return parking_status(car, direct_spot)
    end

    cars = current_cars + [car]
    assignments = assign_cars(cars, preferred_car: car)

    return parking_status unless assignments

    apply_assignments(cars, assignments)
    parking_status(car, car[:spot_type])
  end

  def exit_car(license_plate_no)
    plate = normalize_license_plate(license_plate_no)
    return exit_status unless plate

    @parking_spots.each do |spot_key, cars|
      car = cars.find { |parked_car| parked_car[:license_plate_no] == plate }

      next unless car

      cars.delete(car)
      increment_available(spot_type_for_key(spot_key))
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    shuffle_with_car(car, 'medium')
  end

  def shuffle_large(car)
    shuffle_with_car(car, 'large')
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    plate = car[:license_plate_no] ||
            car[:license_plate] ||
            car[:plate] ||
            car['license_plate_no'] ||
            car['license_plate'] ||
            car['plate']

    "car with license plate no. #{plate} is parked at #{space}"
  end

  def exit_status(plate = nil)
    normalized_plate = normalize_license_plate(plate)
    return 'Car not found' unless normalized_plate

    "car with license plate no. #{normalized_plate} exited"
  end

  def total_available
    @small + @medium + @large
  end

  def total_capacity
    @total_small + @total_medium + @total_large
  end

  def total_occupied
    total_capacity - total_available
  end

  private

  def normalize_capacity(value)
    capacity =
      begin
        Integer(value)
      rescue StandardError
        value.respond_to?(:to_i) ? value.to_i : 0
      end

    [capacity, 0].max
  end

  def normalize_license_plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  rescue StandardError
    nil
  end

  def normalize_car_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  rescue StandardError
    nil
  end

  def build_car(plate, size)
    {
      license_plate_no: plate,
      license_plate: plate,
      plate: plate,
      car_size: size,
      size: size,
      spot_type: nil,
      parked_at: nil
    }
  end

  def normalize_car_hash(car, expected_size = nil)
    return nil unless car.respond_to?(:[])

    plate = normalize_license_plate(
      car[:license_plate_no] ||
      car[:license_plate] ||
      car[:plate] ||
      car['license_plate_no'] ||
      car['license_plate'] ||
      car['plate']
    )

    size = normalize_car_size(
      car[:car_size] ||
      car[:size] ||
      car['car_size'] ||
      car['size'] ||
      expected_size
    )

    return nil unless plate && size
    return nil if expected_size && size != expected_size

    build_car(plate, size)
  end

  def reset_parking_spots
    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }

    @small = @total_small
    @medium = @total_medium
    @large = @total_large
  end

  def current_cars
    @parking_spots.values.flatten
  end

  def parked?(plate)
    current_cars.any? { |car| car[:license_plate_no] == plate }
  end

  def park_car(car, spot_type)
    car[:spot_type] = spot_type
    car[:parked_at] = spot_type
    @parking_spots[SPOT_KEYS[spot_type]] << car
    decrement_available(spot_type)
  end

  def assign_cars(cars, preferred_car: nil)
    available = {
      'small' => @total_small,
      'medium' => @total_medium,
      'large' => @total_large
    }

    assignments = {}

    ordered = cars.each_with_index.sort_by do |car, index|
      [
        PRIORITY.fetch(car[:car_size], 99),
        car.equal?(preferred_car) ? -1 : 0,
        index
      ]
    end

    ordered.each do |car, _index|
      preferences = PREFERENCES[car[:car_size]]
      return nil unless preferences

      spot_type = preferences.find { |candidate| available[candidate].positive? }
      return nil unless spot_type

      assignments[car.object_id] = spot_type
      available[spot_type] -= 1
    end

    assignments
  end

  def apply_assignments(cars, assignments)
    reset_parking_spots

    cars.each do |car|
      spot_type = assignments[car.object_id]
      key = SPOT_KEYS[spot_type]
      return false unless spot_type && key

      car[:spot_type] = spot_type
      car[:parked_at] = spot_type
      @parking_spots[key] << car
      decrement_available(spot_type)
    end

    true
  end

  def shuffle_with_car(car, expected_size)
    normalized_car = normalize_car_hash(car, expected_size)
    return parking_status unless normalized_car
    return parking_status if parked?(normalized_car[:license_plate_no])

    cars = current_cars + [normalized_car]
    assignments = assign_cars(cars, preferred_car: normalized_car)

    return parking_status unless assignments

    apply_assignments(cars, assignments)
    parking_status(normalized_car, normalized_car[:spot_type])
  end

  def available_count(spot_type)
    case spot_type
    when 'small' then @small
    when 'medium' then @medium
    when 'large' then @large
    else 0
    end
  end

  def decrement_available(spot_type)
    case spot_type
    when 'small' then @small -= 1
    when 'medium' then @medium -= 1
    when 'large' then @large -= 1
    end
  end

  def increment_available(spot_type)
    case spot_type
    when 'small' then @small = [@small + 1, @total_small].min
    when 'medium' then @medium = [@medium + 1, @total_medium].min
    when 'large' then @large = [@large + 1, @total_large].min
    end
  end

  def spot_type_for_key(key)
    SPOT_TYPES[key]
  end
end

class ParkingTicket
  attr_reader :id, :ticket_id, :entry_time, :license_plate, :license_plate_no,
              :license, :car_size, :size

  VALID_SIZES = %w[small medium large].freeze

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @ticket_id = @id
    @license_plate = normalize_license_plate(license_plate)
    @license_plate_no = @license_plate
    @license = @license_plate
    @car_size = normalize_car_size_to_string(car_size)
    @size = @car_size
    @entry_time = normalize_time(entry_time)
  end

  def duration_hours(current_time = Time.now)
    now = current_time.is_a?(Time) ? current_time : Time.now
    duration = (now - @entry_time) / 3600.0
    duration = 0.0 if duration.negative?
    duration.round(6)
  rescue StandardError
    0.0
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
  end

  def normalize_license_plate(value)
    return '' if value.nil?

    value.to_s.strip
  rescue StandardError
    ''
  end

  def normalize_car_size_to_string(value)
    return '' if value.nil?

    value.to_s.strip.downcase
  rescue StandardError
    ''
  end

  def normalize_time(value)
    value.is_a?(Time) ? value : Time.now
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

  DAILY_MAXIMUMS = MAX_FEE
  GRACE_PERIOD_HOURS = 0.25
  EPSILON = 1e-6

  def calculate_fee(car_size, duration_hours)
    size = normalize_car_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 unless size && duration
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    hours = rounded_up_hours(duration)
    total = hours * RATES[size]

    [total, MAX_FEE[size]].min.to_f
  rescue StandardError
    0.0
  end

  alias calculate__fee calculate_fee

  private

  def normalize_car_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    RATES.key?(size) ? size : nil
  rescue StandardError
    nil
  end

  def normalize_duration(value)
    duration = Float(value)
    return nil unless duration.finite?

    duration.negative? ? 0.0 : duration
  rescue StandardError
    nil
  end

  def rounded_up_hours(duration)
    nearest_hour = duration.round
    return nearest_hour if (duration - nearest_hour).abs <= EPSILON

    duration.ceil
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  VALID_SIZES = %w[small medium large].freeze

  def initialize(*args, **kwargs)
    options = {}

    if args.length == 1 && args.first.is_a?(Hash)
      options.merge!(args.first)
    else
      options[:small_spots] = args[0] if args.length > 0
      options[:medium_spots] = args[1] if args.length > 1
      options[:large_spots] = args[2] if args.length > 2
    end

    options.merge!(kwargs)

    small_spots = extract_option(options, :small_spots, 'small_spots', :small, 'small')
    medium_spots = extract_option(options, :medium_spots, 'medium_spots', :medium, 'medium')
    large_spots = extract_option(options, :large_spots, 'large_spots', :large, 'large')

    @garage = ParkingGarage.new(small_spots || 0, medium_spots || 0, large_spots || 0)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
    @tix_in_flight = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = normalize_license_plate(plate)
    normalized_size = normalize_car_size(size)

    return admit_failure('No space available') unless normalized_plate && normalized_size
    return admit_failure('No space available') if @active_tickets.key?(normalized_plate)

    message = @garage.admit_car(normalized_plate, normalized_size)

    if parked_message?(message)
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      admit_failure(message)
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_license_plate(plate)
    return exit_failure('Ticket not found') unless normalized_plate

    ticket = @active_tickets[normalized_plate]
    return exit_failure('Ticket not found') unless ticket

    duration = ticket.duration_hours
    message = @garage.exit_car(normalized_plate)

    unless exited_message?(message)
      return {
        success: false,
        message: message,
        fee: 0.0,
        duration_hours: duration
      }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    @active_tickets.delete(normalized_plate)

    {
      success: true,
      message: message,
      fee: fee.to_f,
      duration_hours: duration
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.total_occupied,
      total_available: @garage.total_available
    }
  end

  def find_ticket(plate)
    normalized_plate = normalize_license_plate(plate)
    return nil unless normalized_plate

    @active_tickets[normalized_plate]
  end

  private

  def extract_option(options, *keys)
    keys.each do |key|
      return options[key] if options.key?(key) && !options[key].nil?
    end

    nil
  end

  def normalize_license_plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  rescue StandardError
    nil
  end

  def normalize_car_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  rescue StandardError
    nil
  end

  def parked_message?(message)
    message.is_a?(String) && message.include?(' is parked at ')
  end

  def exited_message?(message)
    message.is_a?(String) && message.end_with?(' exited')
  end

  def admit_failure(message)
    {
      success: false,
      message: message,
      ticket: nil
    }
  end

  def exit_failure(message)
    {
      success: false,
      message: message,
      fee: 0.0,
      duration_hours: 0.0
    }
  end
end