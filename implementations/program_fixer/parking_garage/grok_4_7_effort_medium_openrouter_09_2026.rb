require 'securerandom'

module ParkingUtils
  module_function

  VALID_SIZES = %w[small medium large].freeze
  GRACE_PERIOD = 0.25

  def normalize_plate(plate)
    return nil if plate.nil?

    str = plate.to_s.strip
    str.empty? ? nil : str
  end

  def normalize_size(size)
    return nil if size.nil?

    str = size.to_s.strip.downcase
    VALID_SIZES.include?(str) ? str : nil
  end

  def safe_count(value)
    count = value.to_i
    count.negative? ? 0 : count
  rescue StandardError
    0
  end
end

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = ParkingUtils.safe_count(small)
    @medium = ParkingUtils.safe_count(medium)
    @large = ParkingUtils.safe_count(large)

    @total_small = @small
    @total_medium = @medium
    @total_large = @large

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = ParkingUtils.normalize_plate(license_plate_no)
    size = ParkingUtils.normalize_size(car_size)
    return 'No space available' if plate.nil? || size.nil?
    return 'No space available' if car_parked?(plate)

    car = { plate: plate, size: size }

    case size
    when 'small'
      park_small(car)
    when 'medium'
      park_medium(car)
    when 'large'
      park_large(car)
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = ParkingUtils.normalize_plate(license_plate_no)
    return 'No car found' if plate.nil?

    %i[small medium large].each do |spot_type|
      car = @parking_spots[spot_type].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot_type].delete(car)
      increment_spot(spot_type)
      return exit_status(plate)
    end

    'No car found'
  end

  def shuffle_medium(car)
    return parking_status unless car

    if @small > 0
      victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if victim
        move_car(victim, :medium, :small)
        return park_in(car, :medium)
      end
    end

    if @small > 0
      victim = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if victim
        move_car(victim, :large, :small)
        return park_in(car, :large)
      end
    end

    'No space available'
  end

  def shuffle_large(car)
    return parking_status unless car

    if @medium > 0
      victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      if victim
        move_car(victim, :large, :medium)
        return park_in(car, :large)
      end
    end

    if @small > 0
      victim = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if victim
        move_car(victim, :large, :small)
        return park_in(car, :large)
      end
    end

    if @medium > 0
      victim = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if victim
        move_car(victim, :large, :medium)
        return park_in(car, :large)
      end
    end

    if @small > 0
      medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      small_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if medium_in_large && small_in_medium
        move_car(small_in_medium, :medium, :small)
        move_car(medium_in_large, :large, :medium)
        return park_in(car, :large)
      end
    end

    'No space available'
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : 'No car found'
  end

  def total_available
    @small + @medium + @large
  end

  def total_occupied
    (@total_small + @total_medium + @total_large) - total_available
  end

  private

  def park_small(car)
    if @small > 0
      park_in(car, :small)
    elsif @medium > 0
      park_in(car, :medium)
    elsif @large > 0
      park_in(car, :large)
    else
      'No space available'
    end
  end

  def park_medium(car)
    if @medium > 0
      park_in(car, :medium)
    elsif @large > 0
      park_in(car, :large)
    else
      shuffle_medium(car)
    end
  end

  def park_large(car)
    if @large > 0
      park_in(car, :large)
    else
      shuffle_large(car)
    end
  end

  def park_in(car, spot_type)
    return 'No space available' unless available(spot_type) > 0

    @parking_spots[spot_type] << car
    decrement_spot(spot_type)
    parking_status(car, spot_type.to_s)
  end

  def move_car(car, from_spot, to_spot)
    @parking_spots[from_spot].delete(car)
    increment_spot(from_spot)
    @parking_spots[to_spot] << car
    decrement_spot(to_spot)
  end

  def car_parked?(plate)
    @parking_spots.values.any? { |cars| cars.any? { |c| c[:plate] == plate } }
  end

  def available(spot_type)
    case spot_type
    when :small then @small
    when :medium then @medium
    when :large then @large
    else 0
    end
  end

  def decrement_spot(spot_type)
    case spot_type
    when :small then @small -= 1 if @small > 0
    when :medium then @medium -= 1 if @medium > 0
    when :large then @large -= 1 if @large > 0
    end
  end

  def increment_spot(spot_type)
    case spot_type
    when :small then @small += 1 if @small < @total_small
    when :medium then @medium += 1 if @medium < @total_medium
    when :large then @large += 1 if @large < @total_large
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  alias license_plate_no license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = ParkingUtils.normalize_plate(license_plate) || license_plate.to_s
    @car_size = ParkingUtils.normalize_size(car_size) || car_size.to_s.strip.downcase
    @entry_time = entry_time
  end

  def duration_hours
    return 0.0 if @entry_time.nil?

    ((Time.now - @entry_time) / 3600.0).to_f
  rescue StandardError
    0.0
  end

  def valid?
    duration_hours <= 24.0
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

  def calculate_fee(car_size, duration_hours)
    duration = coerce_duration(duration_hours)
    return 0.0 if duration.nil? || !duration.finite? || duration.negative?
    return 0.0 if duration <= ParkingUtils::GRACE_PERIOD

    size = ParkingUtils.normalize_size(car_size)
    return 0.0 if size.nil?

    billable_hours = (duration - ParkingUtils::GRACE_PERIOD).ceil
    total = billable_hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end

  private

  def coerce_duration(value)
    return nil if value.nil?
    return value.to_f if value.is_a?(Numeric)

    Float(value)
  rescue StandardError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    message = @garage.admit_car(plate, size)

    if message.to_s.include?('is parked at')
      norm_plate = ParkingUtils.normalize_plate(plate)
      norm_size = ParkingUtils.normalize_size(size)
      ticket = ParkingTicket.new(norm_plate, norm_size)
      @active_tickets[norm_plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message.to_s.empty? ? 'No space available' : message, ticket: nil }
    end
  end

  def exit_car(plate)
    key = ParkingUtils.normalize_plate(plate)
    return { success: false, message: 'No car found' } if key.nil?

    ticket = @active_tickets[key]
    return { success: false, message: "car with license plate no. #{key} not found" } unless ticket

    duration = ticket.duration_hours.to_f
    duration = 0.0 if duration.negative? || !duration.finite?
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(key)

    unless message.to_s.include?('exited')
      return { success: false, message: message }
    end

    @active_tickets.delete(key)
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
    key = ParkingUtils.normalize_plate(plate)
    return nil if key.nil?

    @active_tickets[key]
  end
end