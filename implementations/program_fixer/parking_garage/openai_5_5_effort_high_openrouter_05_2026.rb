require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze
  SPOT_TYPES = %w[small medium large].freeze
  ALLOWED_SPOTS = {
    'small'  => %w[small medium large],
    'medium' => %w[medium large],
    'large'  => %w[large]
  }.freeze
  SPOT_ALIASES = {
    small_spot: :small,
    medium_spot: :medium,
    large_spot: :large,
    tiny_spot: :small,
    mid_spot: :medium,
    grande_spot: :large,
    tiny: :small,
    mid: :medium,
    grande: :large
  }.freeze

  attr_reader :parking_spots, :small, :medium, :large

  def self.normalize_license_plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  end

  def self.normalize_car_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  end

  def self.nonnegative_integer(value)
    integer =
      begin
        Integer(value)
      rescue ArgumentError, TypeError
        value.respond_to?(:to_i) ? value.to_i : 0
      end

    [integer, 0].max
  end

  def initialize(small, medium, large)
    @capacity = {
      small: self.class.nonnegative_integer(small),
      medium: self.class.nonnegative_integer(medium),
      large: self.class.nonnegative_integer(large)
    }

    @small = @capacity[:small]
    @medium = @capacity[:medium]
    @large = @capacity[:large]

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }

    @parking_spots.default_proc = proc do |hash, key|
      key_string = key.to_s
      key_symbol = begin
        key.to_sym
      rescue StandardError
        nil
      end

      if SPOT_TYPES.include?(key_string)
        hash[key_string.to_sym]
      elsif key_symbol && SPOT_ALIASES[key_symbol]
        hash[SPOT_ALIASES[key_symbol]]
      end
    end
  end

  def admit_car(license_plate_no, car_size)
    plate = self.class.normalize_license_plate(license_plate_no)
    return 'Invalid license plate' unless plate

    size = self.class.normalize_car_size(car_size)
    return 'Invalid car size' unless size

    return "car with license plate no. #{plate} is already parked" if parked?(plate)

    car = {
      plate: plate,
      license_plate_no: plate,
      license_plate: plate,
      size: size,
      car_size: size
    }

    spot = find_spot_for(size)
    return parking_status unless spot

    park_in_spot(car, spot)
    parking_status(car, spot)
  end

  def exit_car(license_plate_no)
    plate = self.class.normalize_license_plate(license_plate_no)
    return 'Invalid license plate' unless plate

    found = find_car(plate)
    return "car with license plate no. #{plate} not found" unless found

    spot, car = found
    @parking_spots[spot.to_sym].delete(car)
    increment_available(spot)

    exit_status(plate)
  end

  def find_car(license_plate_no)
    plate = self.class.normalize_license_plate(license_plate_no)
    return nil unless plate

    SPOT_TYPES.each do |spot|
      car = @parking_spots[spot.to_sym].find { |parked_car| parked_car[:plate] == plate }
      return [spot, car] if car
    end

    nil
  end

  def parked?(license_plate_no)
    !find_car(license_plate_no).nil?
  end

  def total_occupied
    SPOT_TYPES.inject(0) { |total, spot| total + @parking_spots[spot.to_sym].size }
  end

  def total_available
    @small + @medium + @large
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    plate =
      if car.is_a?(Hash)
        car[:plate] || car['plate'] || car[:license_plate_no] || car['license_plate_no'] || car[:license_plate] || car['license_plate']
      else
        car
      end

    spot_type = normalize_spot_display(space)
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def exit_status(plate = nil)
    normalized_plate = self.class.normalize_license_plate(plate)
    return 'Car not found' unless normalized_plate

    "car with license plate no. #{normalized_plate} exited"
  end

  private

  def find_spot_for(size)
    case size
    when 'small'
      direct_spot_for(%w[small medium large])
    when 'medium'
      direct_spot_for(%w[medium]) ||
        free_medium_spot ||
        direct_spot_for(%w[large]) ||
        free_large_spot
    when 'large'
      direct_spot_for(%w[large]) || free_large_spot
    end
  end

  def direct_spot_for(spots)
    spots.find { |spot| available_count(spot).positive? }
  end

  def free_medium_spot
    return nil unless @small.positive?

    small_car_in_medium = @parking_spots[:medium].find { |car| car[:size] == 'small' }
    return nil unless small_car_in_medium

    move_car_between_spots(small_car_in_medium, 'medium', 'small')
    'medium'
  end

  def free_large_spot
    medium_car_in_large = @parking_spots[:large].find { |car| car[:size] == 'medium' }

    if medium_car_in_large && @medium.positive?
      move_car_between_spots(medium_car_in_large, 'large', 'medium')
      return 'large'
    end

    small_car_in_large = @parking_spots[:large].find { |car| car[:size] == 'small' }

    if small_car_in_large && @small.positive?
      move_car_between_spots(small_car_in_large, 'large', 'small')
      return 'large'
    end

    if small_car_in_large && @medium.positive?
      move_car_between_spots(small_car_in_large, 'large', 'medium')
      return 'large'
    end

    if medium_car_in_large && @small.positive?
      small_car_in_medium = @parking_spots[:medium].find { |car| car[:size] == 'small' }

      if small_car_in_medium
        move_car_between_spots(small_car_in_medium, 'medium', 'small')
        move_car_between_spots(medium_car_in_large, 'large', 'medium')
        return 'large'
      end
    end

    nil
  end

  def park_in_spot(car, spot)
    @parking_spots[spot.to_sym] << car
    decrement_available(spot)
  end

  def move_car_between_spots(car, from_spot, to_spot)
    from_key = from_spot.to_sym
    to_key = to_spot.to_sym

    return false unless car
    return false unless available_count(to_key).positive?

    removed = @parking_spots[from_key].delete(car)
    return false unless removed

    increment_available(from_key)
    @parking_spots[to_key] << car
    decrement_available(to_key)

    true
  end

  def available_count(spot)
    case normalize_spot_key(spot)
    when :small then @small
    when :medium then @medium
    when :large then @large
    else 0
    end
  end

  def increment_available(spot)
    case normalize_spot_key(spot)
    when :small
      @small = [@small + 1, @capacity[:small]].min
    when :medium
      @medium = [@medium + 1, @capacity[:medium]].min
    when :large
      @large = [@large + 1, @capacity[:large]].min
    end
  end

  def decrement_available(spot)
    case normalize_spot_key(spot)
    when :small
      @small -= 1 if @small.positive?
    when :medium
      @medium -= 1 if @medium.positive?
    when :large
      @large -= 1 if @large.positive?
    end
  end

  def normalize_spot_key(spot)
    key = spot.to_s.to_sym
    SPOT_ALIASES[key] || key
  end

  def normalize_spot_display(spot)
    normalize_spot_key(spot).to_s
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :license_plate_no, :entry_time, :car_size
  alias_method :ticket_id, :id

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id

    normalized_plate = ParkingGarage.normalize_license_plate(license_plate)
    @license_plate = normalized_plate || license_plate.to_s.strip
    @license_plate_no = @license_plate

    normalized_size = ParkingGarage.normalize_car_size(car_size)
    @car_size = normalized_size || car_size.to_s.strip.downcase

    @entry_time = normalize_entry_time(entry_time)
  end

  def duration_hours
    seconds = Time.now - @entry_time
    [seconds, 0.0].max / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    SecureRandom.uuid
  end

  def normalize_entry_time(value)
    return value if value.is_a?(Time)
    return value.to_time if value.respond_to?(:to_time)

    Time.now
  rescue StandardError
    Time.now
  end
end

class ParkingFeeCalculator
  RATES = {
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }.freeze

  DAILY_MAXIMUMS = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  MAX_FEE = DAILY_MAXIMUMS
  GRACE_PERIOD_HOURS = 0.25
  GRACE_PERIOD = GRACE_PERIOD_HOURS

  def calculate_fee(car_size, duration_hours)
    size = ParkingGarage.normalize_car_size(car_size)
    return 0.0 unless size

    duration = normalize_duration(duration_hours)
    return 0.0 unless duration
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    hours = duration.ceil
    total = hours * RATES[size]

    [total, DAILY_MAXIMUMS[size]].min.to_f
  end

  alias_method :calculate__fee, :calculate_fee

  private

  def normalize_duration(value)
    duration = Float(value)
    return nil unless duration.finite?
    return 0.0 if duration.negative?

    duration
  rescue ArgumentError, TypeError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(small_count = nil, medium_count = nil, large_count = nil,
                 small_spots: nil, medium_spots: nil, large_spots: nil,
                 small: nil, medium: nil, large: nil)
    if small_count.is_a?(Hash) && medium_count.nil? && large_count.nil?
      options = small_count
      small_total = first_present(options[:small_spots], options['small_spots'], options[:small], options['small'], 0)
      medium_total = first_present(options[:medium_spots], options['medium_spots'], options[:medium], options['medium'], 0)
      large_total = first_present(options[:large_spots], options['large_spots'], options[:large], options['large'], 0)
    else
      small_total = first_present(small_count, small_spots, small, 0)
      medium_total = first_present(medium_count, medium_spots, medium, 0)
      large_total = first_present(large_count, large_spots, large, 0)
    end

    @garage = ParkingGarage.new(small_total, medium_total, large_total)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
    @tix_in_flight = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = normalize_license_plate(plate)
    return { success: false, message: 'Invalid license plate' } unless normalized_plate

    normalized_size = normalize_car_size(size)
    return { success: false, message: 'Invalid car size' } unless normalized_size

    if @active_tickets.key?(normalized_plate)
      return {
        success: false,
        message: "car with license plate no. #{normalized_plate} is already parked"
      }
    end

    message = @garage.admit_car(normalized_plate, normalized_size)

    if parked_message?(message)
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket

      {
        success: true,
        message: message,
        ticket: ticket
      }
    else
      {
        success: false,
        message: message
      }
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_license_plate(plate)
    return { success: false, message: 'Invalid license plate' } unless normalized_plate

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    unless message == "car with license plate no. #{normalized_plate} exited"
      return {
        success: false,
        message: message
      }
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
    normalized_plate = normalize_license_plate(plate)
    return nil unless normalized_plate

    @active_tickets[normalized_plate]
  end

  private

  def first_present(*values)
    values.find { |value| !value.nil? }
  end

  def normalize_license_plate(value)
    ParkingGarage.normalize_license_plate(value)
  end

  def normalize_car_size(value)
    ParkingGarage.normalize_car_size(value)
  end

  def parked_message?(message)
    message.is_a?(String) && message.include?(' is parked at ')
  end
end