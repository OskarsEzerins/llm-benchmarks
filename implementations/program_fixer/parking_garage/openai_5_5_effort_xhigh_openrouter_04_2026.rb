require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots

  VALID_SIZES = %w[small medium large].freeze
  SPOT_TYPES = [:small, :medium, :large].freeze
  PREFERRED_SPOTS = {
    'small' => [:small, :medium, :large],
    'medium' => [:medium, :large],
    'large' => [:large]
  }.freeze

  NO_SPACE_MESSAGE = 'No space available'.freeze
  CAR_NOT_FOUND_MESSAGE = 'Car not found'.freeze

  SPOT_KEY_ALIASES = {
    'small' => :small,
    'small_spot' => :small,
    'tiny' => :small,
    'tiny_spot' => :small,
    'medium' => :medium,
    'medium_spot' => :medium,
    'mid' => :medium,
    'mid_spot' => :medium,
    'large' => :large,
    'large_spot' => :large,
    'grande' => :large,
    'grande_spot' => :large
  }.freeze

  class ParkingSpotsHash < Hash
    def self.canonical_key(key)
      ParkingGarage::SPOT_KEY_ALIASES[key.to_s.strip.downcase]
    rescue StandardError
      nil
    end

    def [](key)
      super(self.class.canonical_key(key) || key)
    end

    def []=(key, value)
      super(self.class.canonical_key(key) || key, value)
    end

    def fetch(key, *args, &block)
      canonical = self.class.canonical_key(key) || key
      block_given? ? super(canonical, &block) : super(canonical, *args)
    end

    def key?(key)
      super(self.class.canonical_key(key) || key)
    end
    alias has_key? key?
    alias include? key?
    alias member? key?

    def delete(key)
      super(self.class.canonical_key(key) || key)
    end

    def values_at(*keys)
      keys.map { |key| self[key] }
    end
  end

  def initialize(small = 0, medium = 0, large = 0)
    @capacity = {
      small: normalize_count(small),
      medium: normalize_count(medium),
      large: normalize_count(large)
    }
    @parking_spots = empty_parking_spots
    recalculate_availability!
  end

  def small
    recalculate_availability!
    @small
  end

  def medium
    recalculate_availability!
    @medium
  end

  def large
    recalculate_availability!
    @large
  end

  alias smalls small
  alias mediums medium
  alias larges large

  def admit_car(license_plate_no, car_size)
    recalculate_availability!

    plate = normalize_license_plate(license_plate_no)
    size = normalize_car_size(car_size)
    return parking_status unless plate && size

    car = { plate: plate, size: size }

    PREFERRED_SPOTS[size].each do |spot|
      return park_car_in_spot(car, spot) if available_count(spot) > 0
    end

    PREFERRED_SPOTS[size].each do |spot|
      return parking_status(car, spot.to_s) if reassign_with_forced_car(car, spot)
    end

    parking_status
  end

  def exit_car(license_plate_no)
    recalculate_availability!

    plate = normalize_license_plate(license_plate_no)
    return exit_status unless plate

    SPOT_TYPES.each do |spot|
      spots = @parking_spots[spot] || []
      index = spots.index { |parked_car| normalize_license_plate(car_plate(parked_car)) == plate }
      next if index.nil?

      spots.delete_at(index)
      recalculate_availability!
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    plate = normalize_license_plate(car_plate(car))
    return parking_status unless plate

    candidate = { plate: plate, size: 'medium' }

    [:medium, :large].each do |spot|
      return parking_status(candidate, spot.to_s) if reassign_with_forced_car(candidate, spot)
    end

    parking_status
  end

  def shuffle_large(car)
    plate = normalize_license_plate(car_plate(car))
    return parking_status unless plate

    candidate = { plate: plate, size: 'large' }
    return parking_status(candidate, 'large') if reassign_with_forced_car(candidate, :large)

    parking_status
  end

  def available_spots
    recalculate_availability!
    { small: @small, medium: @medium, large: @large }
  end

  def total_occupied
    SPOT_TYPES.inject(0) { |sum, spot| sum + (@parking_spots[spot] || []).size }
  end

  def total_available
    recalculate_availability!
    @small + @medium + @large
  end

  def status
    recalculate_availability!
    {
      small_available: @small,
      medium_available: @medium,
      large_available: @large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end
  alias garage_status status

  def parking_status(car = nil, space = nil)
    plate = normalize_license_plate(car_plate(car)) if car
    return "car with license plate no. #{plate} is parked at #{space}" if plate && space

    NO_SPACE_MESSAGE
  end

  def exit_status(plate = nil)
    normalized_plate = normalize_license_plate(plate)
    return "car with license plate no. #{normalized_plate} exited" if normalized_plate

    CAR_NOT_FOUND_MESSAGE
  end

  private

  def empty_parking_spots
    ParkingSpotsHash.new.tap do |spots|
      SPOT_TYPES.each { |spot| spots[spot] = [] }
    end
  end

  def normalize_count(value)
    number =
      begin
        Integer(value)
      rescue StandardError
        begin
          value.to_i
        rescue StandardError
          0
        end
      end

    number < 0 ? 0 : number
  end

  def normalize_license_plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  rescue StandardError
    nil
  end

  def normalize_car_size(value)
    size = value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  rescue StandardError
    nil
  end

  def canonical_spot_key(key)
    SPOT_KEY_ALIASES[key.to_s.strip.downcase]
  rescue StandardError
    nil
  end

  def available_count(spot)
    canonical = canonical_spot_key(spot)
    return 0 unless canonical

    occupied = (@parking_spots[canonical] || []).size
    available = @capacity[canonical].to_i - occupied
    available < 0 ? 0 : available
  end

  def recalculate_availability!
    @small = available_count(:small)
    @medium = available_count(:medium)
    @large = available_count(:large)
  end

  def park_car_in_spot(car, spot)
    canonical = canonical_spot_key(spot)
    return parking_status unless canonical && available_count(canonical) > 0

    @parking_spots[canonical] ||= []
    @parking_spots[canonical] << car
    recalculate_availability!
    parking_status(car, canonical.to_s)
  end

  def reassign_with_forced_car(car, forced_spot)
    canonical = canonical_spot_key(forced_spot)
    return false unless canonical

    capacities = @capacity.dup
    return false unless capacities[canonical].to_i > 0

    capacities[canonical] -= 1

    assignment = assign_cars_to_capacities(parked_cars, capacities)
    return false unless assignment

    SPOT_TYPES.each do |spot|
      @parking_spots[spot] ||= []
      @parking_spots[spot].clear
      @parking_spots[spot].concat(assignment[spot])
    end

    @parking_spots[canonical] << car
    recalculate_availability!
    true
  end

  def parked_cars
    SPOT_TYPES.inject([]) { |cars, spot| cars.concat(@parking_spots[spot] || []) }
  end

  def assign_cars_to_capacities(cars, capacities)
    assignment = empty_parking_spots
    remaining = capacities.dup
    cars_by_size = { 'large' => [], 'medium' => [], 'small' => [] }

    cars.each do |car|
      size = normalize_car_size(car_size_value(car))
      return nil unless size

      cars_by_size[size] << car
    end

    cars_by_size['large'].each do |car|
      return nil unless place_car_in_assignment(car, [:large], assignment, remaining)
    end

    cars_by_size['medium'].each do |car|
      return nil unless place_car_in_assignment(car, [:medium, :large], assignment, remaining)
    end

    cars_by_size['small'].each do |car|
      return nil unless place_car_in_assignment(car, [:small, :medium, :large], assignment, remaining)
    end

    assignment
  end

  def place_car_in_assignment(car, spot_preferences, assignment, remaining)
    spot_preferences.each do |spot|
      next unless remaining[spot].to_i > 0

      assignment[spot] << car
      remaining[spot] -= 1
      return true
    end

    false
  end

  def car_plate(car)
    return nil unless car.respond_to?(:[])

    car[:plate] ||
      car['plate'] ||
      car[:license_plate_no] ||
      car['license_plate_no'] ||
      car[:license_plate] ||
      car['license_plate']
  rescue StandardError
    nil
  end

  def car_size_value(car)
    return nil unless car.respond_to?(:[])

    car[:size] ||
      car['size'] ||
      car[:car_size] ||
      car['car_size']
  rescue StandardError
    nil
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate, :license_plate_no

  VALID_SIZES = %w[small medium large].freeze
  EXPIRATION_HOURS = 24.0

  @@issued_ticket_ids = {}
  @@ticket_sequence = 0

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = normalize_license_plate_for_storage(license_plate)
    @license_plate_no = @license_plate
    @license = @license_plate
    @car_size = normalize_car_size_for_storage(car_size)
    @entry_time = normalize_time(entry_time)
  end

  def ticket_id
    @id
  end

  def license
    @license_plate
  end

  def duration_hours(current_time = Time.now)
    current = normalize_time(current_time)
    entry = normalize_time(@entry_time)
    seconds = current.to_f - entry.to_f
    seconds = 0.0 if seconds < 0.0
    seconds / 3600.0
  rescue StandardError
    0.0
  end

  def valid?
    duration_hours <= EXPIRATION_HOURS
  end

  def expired?
    !valid?
  end

  private

  def generate_ticket_id
    ticket_id = SecureRandom.uuid

    if @@issued_ticket_ids.key?(ticket_id)
      @@ticket_sequence += 1
      ticket_id = "#{ticket_id}-#{@@ticket_sequence}"
    end

    @@issued_ticket_ids[ticket_id] = true
    ticket_id
  end

  def normalize_license_plate_for_storage(value)
    value.nil? ? '' : value.to_s.strip
  rescue StandardError
    ''
  end

  def normalize_car_size_for_storage(value)
    value.to_s.strip.downcase
  rescue StandardError
    ''
  end

  def normalize_time(value)
    return value if value.is_a?(Time)
    return Time.at(value) if value.is_a?(Numeric)

    if value.respond_to?(:to_time)
      converted = value.to_time
      return converted if converted.is_a?(Time)
    end

    Time.now
  rescue StandardError
    Time.now
  end
end

class ParkingFeeCalculator
  RATES = begin
    rates = Hash.new do |hash, key|
      begin
        hash[key.to_s.strip.downcase] if key.respond_to?(:to_s)
      rescue StandardError
        nil
      end
    end
    rates['small'] = 2.0
    rates['medium'] = 3.0
    rates['large'] = 5.0
    rates.freeze
  end

  DAILY_MAXIMUMS = begin
    maximums = Hash.new do |hash, key|
      begin
        hash[key.to_s.strip.downcase] if key.respond_to?(:to_s)
      rescue StandardError
        nil
      end
    end
    maximums['small'] = 20.0
    maximums['medium'] = 30.0
    maximums['large'] = 50.0
    maximums.freeze
  end

  MAX_FEE = DAILY_MAXIMUMS
  GRACE_PERIOD_HOURS = 0.25
  GRACE_PERIOD = GRACE_PERIOD_HOURS

  def calculate_fee(car_size, duration_hours)
    size = normalize_car_size(car_size)
    return 0.0 unless size

    duration = normalize_duration(duration_hours)
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    billable_hours = (duration - GRACE_PERIOD_HOURS).ceil
    fee = billable_hours * RATES[size]
    [fee, DAILY_MAXIMUMS[size]].min.to_f
  rescue StandardError
    0.0
  end

  alias calculate__fee calculate_fee

  private

  def normalize_car_size(value)
    size = value.to_s.strip.downcase
    RATES.key?(size) ? size : nil
  rescue StandardError
    nil
  end

  def normalize_duration(value)
    duration = Float(value)
    return 0.0 unless duration.finite?
    return 0.0 if duration < 0.0

    duration
  rescue StandardError
    0.0
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  ALREADY_PARKED_MESSAGE = 'Car already parked'.freeze
  TICKET_NOT_FOUND_MESSAGE = 'Ticket not found'.freeze

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **options)
    if small_spots.is_a?(Hash) && medium_spots.nil? && large_spots.nil?
      options = small_spots.merge(options)
      small_spots = nil
    end

    small_spots = option_value(options, small_spots, :small_spots, 'small_spots', :small, 'small')
    medium_spots = option_value(options, medium_spots, :medium_spots, 'medium_spots', :medium, 'medium')
    large_spots = option_value(options, large_spots, :large_spots, 'large_spots', :large, 'large')

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
    @tix_in_flight = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = normalize_license_plate(plate)
    normalized_size = normalize_car_size(size)

    return { success: false, message: ParkingGarage::NO_SPACE_MESSAGE } unless normalized_plate && normalized_size
    return { success: false, message: ALREADY_PARKED_MESSAGE } if @active_tickets.key?(normalized_plate)

    message = @garage.admit_car(normalized_plate, normalized_size)

    if parked_message?(message)
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_license_plate(plate)
    return { success: false, message: TICKET_NOT_FOUND_MESSAGE } unless normalized_plate

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: TICKET_NOT_FOUND_MESSAGE } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    return { success: false, message: message } unless exited_message?(message)

    @active_tickets.delete(normalized_plate)
    {
      success: true,
      message: message,
      fee: fee.to_f,
      duration_hours: duration.to_f
    }
  end

  def garage_status
    @garage.status
  end
  alias status garage_status

  def find_ticket(plate)
    normalized_plate = normalize_license_plate(plate)
    return nil unless normalized_plate

    @active_tickets[normalized_plate]
  end

  def tickets
    @active_tickets
  end

  def tix_in_flight
    @active_tickets
  end

  private

  def option_value(options, current, *keys)
    keys.each do |key|
      return options[key] if options.key?(key)
    end

    current
  end

  def normalize_license_plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  rescue StandardError
    nil
  end

  def normalize_car_size(value)
    size = value.to_s.strip.downcase
    ParkingGarage::VALID_SIZES.include?(size) ? size : nil
  rescue StandardError
    nil
  end

  def parked_message?(message)
    message.is_a?(String) && message.include?(' is parked at ')
  end

  def exited_message?(message)
    message.is_a?(String) && message.end_with?(' exited')
  end
end