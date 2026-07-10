require 'securerandom'

class ParkingGarage
  SPOT_ORDER = %w[small medium large].freeze
  SIZE_TO_SPOTS = {
    'small' => %w[small medium large].freeze,
    'medium' => %w[medium large].freeze,
    'large' => %w[large].freeze
  }.freeze

  class SpotMap < Hash
    ALIASES = {
      small: :small_spot,
      medium: :medium_spot,
      large: :large_spot,
      tiny_spot: :small_spot,
      mid_spot: :medium_spot,
      grande_spot: :large_spot
    }.freeze

    def [](key)
      super(canonical_key(key))
    end

    def []=(key, value)
      super(canonical_key(key), value)
    end

    def fetch(key, *args, &block)
      super(canonical_key(key), *args, &block)
    end

    def key?(key)
      super(canonical_key(key))
    end

    alias include? key?
    alias has_key? key?

    private

    def canonical_key(key)
      symbol = key.is_a?(String) ? key.to_sym : key
      ALIASES.fetch(symbol, symbol)
    end
  end

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = normalize_capacity(small)
    @medium = normalize_capacity(medium)
    @large = normalize_capacity(large)

    @parking_spots = SpotMap.new
    @parking_spots[:small_spot] = []
    @parking_spots[:medium_spot] = []
    @parking_spots[:large_spot] = []
  end

  def self.normalize_license_plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  rescue StandardError
    nil
  end

  def self.normalize_car_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    SIZE_TO_SPOTS.key?(size) ? size : nil
  rescue StandardError
    nil
  end

  def admit_car(license_plate_no, car_size)
    plate = self.class.normalize_license_plate(license_plate_no)
    size = self.class.normalize_car_size(car_size)

    return parking_status unless plate && size
    return already_parked_status(plate) if parked?(plate)

    car = { plate: plate, size: size }
    spot = first_available_spot(size)

    if spot
      occupy(car, spot)
      return parking_status(car, spot)
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
    plate = self.class.normalize_license_plate(license_plate_no)
    return exit_status unless plate

    found = find_car(plate)
    return exit_status unless found

    car, spot = found
    @parking_spots[spot_key(spot)].delete(car)
    increment_available(spot)

    exit_status(plate)
  end

  def parked?(license_plate_no)
    plate = self.class.normalize_license_plate(license_plate_no)
    return false unless plate

    !find_car(plate).nil?
  end

  def total_occupied
    SPOT_ORDER.sum { |spot| @parking_spots[spot_key(spot)].length }
  end

  def total_available
    @small + @medium + @large
  end

  def shuffle_medium(car)
    normalized_car = normalize_car(car)
    return parking_status unless normalized_car && normalized_car[:size] == 'medium'

    spot =
      if make_space_in('medium')
        'medium'
      elsif make_space_in('large')
        'large'
      end

    return parking_status unless spot

    occupy(normalized_car, spot)
    parking_status(normalized_car, spot)
  end

  def shuffle_large(car)
    normalized_car = normalize_car(car)
    return parking_status unless normalized_car && normalized_car[:size] == 'large'
    return parking_status unless make_space_in('large')

    occupy(normalized_car, 'large')
    parking_status(normalized_car, 'large')
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    plate = self.class.normalize_license_plate(car[:plate] || car['plate'])
    spot = self.class.normalize_car_size(space)
    return 'No space available' unless plate && spot

    "car with license plate no. #{plate} is parked at #{spot}"
  end

  def exit_status(plate = nil)
    normalized_plate = self.class.normalize_license_plate(plate)
    return 'No car found' unless normalized_plate

    "car with license plate no. #{normalized_plate} exited"
  end

  private

  def normalize_capacity(value)
    amount = value.to_i
    amount.negative? ? 0 : amount
  rescue StandardError
    0
  end

  def normalize_car(car)
    return nil unless car.is_a?(Hash)

    plate = self.class.normalize_license_plate(
      car[:plate] || car['plate'] || car[:license_plate] || car['license_plate']
    )
    size = self.class.normalize_car_size(car[:size] || car['size'])

    return nil unless plate && size

    { plate: plate, size: size }
  end

  def already_parked_status(plate)
    "car with license plate no. #{plate} is already parked"
  end

  def spot_key(spot)
    "#{spot}_spot".to_sym
  end

  def first_available_spot(car_size)
    SIZE_TO_SPOTS[car_size].find { |spot| available_count(spot).positive? }
  end

  def available_count(spot)
    case spot
    when 'small' then @small
    when 'medium' then @medium
    when 'large' then @large
    else 0
    end
  end

  def decrement_available(spot)
    case spot
    when 'small' then @small -= 1
    when 'medium' then @medium -= 1
    when 'large' then @large -= 1
    end
  end

  def increment_available(spot)
    case spot
    when 'small' then @small += 1
    when 'medium' then @medium += 1
    when 'large' then @large += 1
    end
  end

  def occupy(car, spot)
    @parking_spots[spot_key(spot)] << car
    decrement_available(spot)
  end

  def find_car(plate)
    SPOT_ORDER.each do |spot|
      car = @parking_spots[spot_key(spot)].find { |parked_car| parked_car[:plate] == plate }
      return [car, spot] if car
    end

    nil
  end

  def make_space_in(source_spot)
    occupants = @parking_spots[spot_key(source_spot)].dup

    occupants.each do |occupant|
      lower_compatible_spots(occupant[:size], source_spot).each do |destination_spot|
        if available_count(destination_spot).positive? || make_space_in(destination_spot)
          move_car(occupant, source_spot, destination_spot)
          return true
        end
      end
    end

    false
  end

  def lower_compatible_spots(car_size, source_spot)
    source_index = SPOT_ORDER.index(source_spot)
    return [] unless source_index

    SIZE_TO_SPOTS.fetch(car_size, []).select do |spot|
      SPOT_ORDER.index(spot) < source_index
    end
  end

  def move_car(car, source_spot, destination_spot)
    @parking_spots[spot_key(source_spot)].delete(car)
    increment_available(source_spot)

    @parking_spots[spot_key(destination_spot)] << car
    decrement_available(destination_spot)
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate, :license_plate_no, :license

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = ParkingGarage.normalize_license_plate(license_plate) || ''
    @license_plate_no = @license_plate
    @license = @license_plate
    @car_size = ParkingGarage.normalize_car_size(car_size) || ''
    @entry_time = normalize_entry_time(entry_time)
  end

  def duration_hours
    elapsed_seconds = Time.now - @entry_time
    return 0.0 unless elapsed_seconds.is_a?(Numeric)

    elapsed_seconds = elapsed_seconds.to_f
    return 0.0 unless elapsed_seconds.finite?

    [elapsed_seconds / 3600.0, 0.0].max
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

  def normalize_entry_time(value)
    return value if value.is_a?(Time)

    converted = value.to_time if value.respond_to?(:to_time)
    converted.is_a?(Time) ? converted : Time.now
  rescue StandardError
    Time.now
  end
end

class ParkingFeeCalculator
  GRACE_PERIOD_HOURS = 0.25

  RATES = {
    small: 2.0,
    medium: 3.0,
    large: 5.0
  }.freeze

  MAX_FEE = {
    small: 20.0,
    medium: 30.0,
    large: 50.0
  }.freeze

  def calculate_fee(car_size, duration_hours)
    size = ParkingGarage.normalize_car_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 unless size && duration
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    hours = duration.ceil
    total = hours * RATES.fetch(size.to_sym)

    [total, MAX_FEE.fetch(size.to_sym)].min.to_f
  end

  private

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
  attr_reader :garage, :active_tickets

  def initialize(*args, **keyword_options)
    options = {}

    if args.first.is_a?(Hash)
      options.merge!(args.shift)
    end

    options.merge!(keyword_options)

    has_small, small_spots = configured_option(options, :small_spots, :small)
    has_medium, medium_spots = configured_option(options, :medium_spots, :medium)
    has_large, large_spots = configured_option(options, :large_spots, :large)

    small_spots = args.shift unless has_small
    medium_spots = args.shift unless has_medium
    large_spots = args.shift unless has_large

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
    @tix_in_flight = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = ParkingGarage.normalize_license_plate(plate)

    if normalized_plate && @active_tickets.key?(normalized_plate)
      return {
        success: false,
        message: "car with license plate no. #{normalized_plate} is already parked"
      }
    end

    message = @garage.admit_car(plate, size)

    unless parked_message?(message)
      return { success: false, message: message }
    end

    ticket = ParkingTicket.new(
      normalized_plate,
      ParkingGarage.normalize_car_size(size)
    )

    @active_tickets[normalized_plate] = ticket

    {
      success: true,
      message: message,
      ticket: ticket
    }
  end

  def exit_car(plate)
    normalized_plate = ParkingGarage.normalize_license_plate(plate)
    ticket = normalized_plate && @active_tickets[normalized_plate]

    return { success: false, message: 'No active ticket found' } unless ticket
    return { success: false, message: 'No parked car found' } unless @garage.parked?(normalized_plate)

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    unless exited_message?(message)
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
      total_occupied: @garage.total_occupied,
      total_available: @garage.total_available
    }
  end

  def find_ticket(plate)
    normalized_plate = ParkingGarage.normalize_license_plate(plate)
    normalized_plate ? @active_tickets[normalized_plate] : nil
  end

  private

  def configured_option(options, *names)
    names.each do |name|
      return [true, options[name]] if options.key?(name)

      string_name = name.to_s
      return [true, options[string_name]] if options.key?(string_name)
    end

    [false, nil]
  end

  def parked_message?(message)
    message.is_a?(String) &&
      message.start_with?('car with license plate no. ') &&
      message.include?(' is parked at ')
  end

  def exited_message?(message)
    message.is_a?(String) &&
      message.start_with?('car with license plate no. ') &&
      message.end_with?(' exited')
  end
end