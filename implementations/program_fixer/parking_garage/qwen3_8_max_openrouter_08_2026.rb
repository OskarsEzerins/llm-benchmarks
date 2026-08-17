require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  NO_SPACE_MESSAGE = 'No space available'.freeze
  VALID_SIZES = %w[small medium large].freeze

  def initialize(small = 0, medium = 0, large = 0)
    @small = safe_count(small)
    @medium = safe_count(medium)
    @large = safe_count(large)
    @parking_spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)

    return NO_SPACE_MESSAGE unless plate && size
    return NO_SPACE_MESSAGE if car_present?(plate)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        park(car, :small)
      elsif @medium > 0
        park(car, :medium)
      elsif @large > 0
        park(car, :large)
      else
        NO_SPACE_MESSAGE
      end
    when 'medium'
      if @medium > 0
        park(car, :medium)
      elsif @large > 0
        park(car, :large)
      else
        NO_SPACE_MESSAGE
      end
    when 'large'
      if @large > 0
        park(car, :large)
      else
        shuffle_for_large(car) || NO_SPACE_MESSAGE
      end
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'car not found' unless plate

    %i[small medium large].each do |spot_type|
      car = @parking_spots[spot_type].find { |parked_car| parked_car[:plate] == plate }
      next unless car

      @parking_spots[spot_type].delete(car)
      increment_spot(spot_type)
      return "car with license plate no. #{plate} exited"
    end

    "car with license plate no. #{plate} not found"
  end

  def car_present?(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return false unless plate

    @parking_spots.values.any? { |cars| cars.any? { |car| car[:plate] == plate } }
  end

  def total_occupied
    @parking_spots.values.reduce(0) { |total, cars| total + cars.size }
  end

  def total_available
    @small + @medium + @large
  end

  private

  def safe_count(value)
    count = value.to_i
    count.negative? ? 0 : count
  rescue StandardError
    0
  end

  def normalize_plate(plate)
    return nil if plate.nil?

    plate_string = plate.to_s.strip
    plate_string.empty? ? nil : plate_string
  rescue StandardError
    nil
  end

  def normalize_size(size)
    return nil if size.nil?

    size_string = size.to_s.strip.downcase
    VALID_SIZES.include?(size_string) ? size_string : nil
  rescue StandardError
    nil
  end

  def park(car, spot_type)
    @parking_spots[spot_type] << car
    decrement_spot(spot_type)
    "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
  end

  def decrement_spot(spot_type)
    case spot_type
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
  end

  def increment_spot(spot_type)
    case spot_type
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end
  end

  def shuffle_for_large(car)
    @parking_spots[:large].dup.each do |occupant|
      target = relocation_target(occupant)
      next unless target

      @parking_spots[:large].delete(occupant)
      increment_spot(:large)

      @parking_spots[target] << occupant
      decrement_spot(target)

      return park(car, :large)
    end

    nil
  end

  def relocation_target(occupant)
    case occupant[:size].to_s
    when 'small'
      return :small if @small > 0
      return :medium if @medium > 0
    when 'medium'
      return :medium if @medium > 0
    end

    nil
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  VALID_SIZES = %w[small medium large].freeze
  EXPIRY_EPSILON = 0.000000001

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = normalize_plate(license_plate).to_s
    @car_size = normalize_size(car_size) || car_size.to_s.strip.downcase
    @entry_time = parse_entry_time(entry_time)
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).to_f
  rescue StandardError
    0.0
  end

  def valid?
    hours = duration_hours
    hours >= 0 && hours <= 24.0 + EXPIRY_EPSILON
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    plate_string = plate.to_s.strip
    plate_string.empty? ? nil : plate_string
  rescue StandardError
    nil
  end

  def normalize_size(size)
    return nil if size.nil?

    size_string = size.to_s.strip.downcase
    VALID_SIZES.include?(size_string) ? size_string : nil
  rescue StandardError
    nil
  end

  def parse_entry_time(value)
    parsed =
      if value.nil?
        Time.now
      elsif value.is_a?(Time)
        value
      elsif value.is_a?(Numeric)
        Time.at(value)
      elsif value.respond_to?(:to_time)
        value.to_time
      else
        Time.now
      end

    parsed.is_a?(Time) ? parsed : Time.now
  rescue StandardError
    Time.now
  end
end

class ParkingFeeCalculator
  GRACE_PERIOD_HOURS = 0.25
  FLOAT_EPSILON = 0.000000001

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

  def calculate_fee(car_size, duration_hours)
    size = normalize_size(car_size)
    hours = normalize_duration(duration_hours)

    return 0.0 unless size && hours
    return 0.0 if hours <= GRACE_PERIOD_HOURS + FLOAT_EPSILON

    billable = hours - GRACE_PERIOD_HOURS
    billable_hours = billable > 24.0 ? 24 : (billable - FLOAT_EPSILON).ceil
    billable_hours = 1 if billable_hours < 1

    total = billable_hours * RATES[size]
    [total, DAILY_MAXIMUMS[size]].min.to_f
  end

  private

  def normalize_size(size)
    return nil if size.nil?

    size_string = size.to_s.strip.downcase
    RATES.key?(size_string) ? size_string : nil
  rescue StandardError
    nil
  end

  def normalize_duration(value)
    return nil if value.nil?

    hours = Float(value)
    return nil unless hours.finite?

    hours.negative? ? nil : hours
  rescue StandardError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage, :active_tickets, :fee_calculator

  def initialize(*args, **kwargs)
    small, medium, large = extract_spot_counts(args, kwargs)
    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(license_plate, car_size)
    plate = normalize_plate(license_plate)
    size = normalize_size(car_size)

    return { success: false, message: ParkingGarage::NO_SPACE_MESSAGE } unless plate && size

    if @active_tickets.key?(plate)
      if @garage.car_present?(plate)
        return { success: false, message: ParkingGarage::NO_SPACE_MESSAGE }
      else
        @active_tickets.delete(plate)
      end
    end

    result = @garage.admit_car(plate, size)

    if result.to_s.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(license_plate)
    plate = normalize_plate(license_plate)
    return { success: false, message: 'Invalid license plate' } unless plate

    ticket = @active_tickets[plate]
    unless ticket
      return { success: false, message: "No ticket found for car with license plate no. #{plate}" }
    end

    garage_result = @garage.exit_car(plate)
    unless garage_result.to_s.include?('exited')
      @active_tickets.delete(plate)
      return { success: false, message: garage_result }
    end

    duration = ticket.duration_hours.to_f
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration).to_f
    @active_tickets.delete(plate)

    {
      success: true,
      message: "car with license plate no. #{plate} exited",
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

  def find_ticket(license_plate)
    plate = normalize_plate(license_plate)
    return nil unless plate

    @active_tickets[plate]
  end

  private

  def extract_spot_counts(args, kwargs)
    options = kwargs.dup
    positional = args.dup

    if positional.first.is_a?(Hash)
      options = positional.shift.merge(options)
    end

    small = positional[0]
    medium = positional[1]
    large = positional[2]

    small = option_value(options, :small_spots, :small, 'small_spots', 'small') if small.nil?
    medium = option_value(options, :medium_spots, :medium, 'medium_spots', 'medium') if medium.nil?
    large = option_value(options, :large_spots, :large, 'large_spots', 'large') if large.nil?

    [small || 0, medium || 0, large || 0]
  end

  def option_value(options, *keys)
    return 0 unless options.respond_to?(:key?)

    keys.each do |key|
      return options[key] if options.key?(key)
    end

    0
  end

  def normalize_plate(plate)
    return nil if plate.nil?

    plate_string = plate.to_s.strip
    plate_string.empty? ? nil : plate_string
  rescue StandardError
    nil
  end

  def normalize_size(size)
    return nil if size.nil?

    size_string = size.to_s.strip.downcase
    %w[small medium large].include?(size_string) ? size_string : nil
  rescue StandardError
    nil
  end
end