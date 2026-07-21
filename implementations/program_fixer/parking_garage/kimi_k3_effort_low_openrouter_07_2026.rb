require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze
  SPOT_KEYS = {
    'small' => :small,
    'medium' => :medium,
    'large' => :large
  }.freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large = [large.to_i, 0].max

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)

    return 'Invalid license plate' if plate.empty?
    return 'Invalid car size' unless VALID_SIZES.include?(size)
    return "car with license plate no. #{plate} is already parked" if parked?(plate)

    kar = { plate: plate, size: size }

    case size
    when 'small'
      park_in_first_available(kar, %w[small medium large])
    when 'medium'
      park_in_first_available(kar, %w[medium large])
    when 'large'
      if @large.positive?
        park_car(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)

    SPOT_KEYS.each_value do |spot_key|
      car = @parking_spots[spot_key].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot_key].delete(car)
      increment_available(spot_key)
      return exit_status(plate)
    end

    "car with license plate no. #{plate} not found"
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

  private

  def normalize_plate(license_plate_no)
    license_plate_no.to_s.strip
  end

  def normalize_size(car_size)
    car_size.to_s.strip.downcase
  end

  def parked?(plate)
    @parking_spots.values.any? { |cars| cars.any? { |car| car[:plate] == plate } }
  end

  def park_in_first_available(kar, preferences)
    preferences.each do |spot_type|
      next unless available_count(spot_type).positive?

      return park_car(kar, spot_type)
    end

    parking_status
  end

  def park_car(kar, spot_type)
    key = SPOT_KEYS[spot_type]
    @parking_spots[key] << kar
    decrement_available(key)
    parking_status(kar, spot_type)
  end

  def available_count(spot_type)
    instance_variable_get("@#{spot_type}")
  end

  def increment_available(spot_key)
    instance_variable_set("@#{spot_key}", instance_variable_get("@#{spot_key}") + 1)
  end

  def decrement_available(spot_key)
    instance_variable_set("@#{spot_key}", instance_variable_get("@#{spot_key}") - 1)
  end

  def shuffle_large(kar)
    large_cars = @parking_spots[:large]

    medium_victim = large_cars.find { |car| car[:size] == 'medium' }
    if medium_victim && @medium.positive?
      move_car(medium_victim, :large, :medium)
      return park_car(kar, 'large')
    end

    small_victim = large_cars.find { |car| car[:size] == 'small' }
    if small_victim
      if @small.positive?
        move_car(small_victim, :large, :small)
        return park_car(kar, 'large')
      elsif @medium.positive?
        move_car(small_victim, :large, :medium)
        return park_car(kar, 'large')
      end
    end

    parking_status
  end

  def move_car(car, from_key, to_key)
    @parking_spots[from_key].delete(car)
    increment_available(from_key)
    @parking_spots[to_key] << car
    decrement_available(to_key)
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24.0
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

  DAILY_MAX = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    duration = begin
      Float(duration_hours)
    rescue ArgumentError, TypeError
      nil
    end

    return 0.0 unless RATES.key?(size)
    return 0.0 if duration.nil? || duration.negative? || duration <= GRACE_PERIOD_HOURS

    billable_hours = (duration - GRACE_PERIOD_HOURS).ceil
    fee = billable_hours * RATES[size]
    [fee, DAILY_MAX[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)

    if result.to_s.include?('is parked at')
      key = normalize_plate(plate)
      ticket = ParkingTicket.new(key, size)
      @active_tickets[key] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result, ticket: nil }
    end
  end

  def exit_car(plate)
    key = normalize_plate(plate)
    ticket = @active_tickets[key]

    unless ticket
      return {
        success: false,
        message: "car with license plate no. #{key} not found",
        fee: 0.0,
        duration_hours: 0.0
      }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(key)
    @active_tickets.delete(key)

    {
      success: true,
      message: result,
      fee: fee.to_f,
      duration_hours: duration.to_f
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.parking_spots.values.sum(&:size),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[normalize_plate(plate)]
  end

  private

  def normalize_plate(plate)
    plate.to_s.strip
  end
end