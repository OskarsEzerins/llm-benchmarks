require 'securerandom'
require 'time'

class ParkingGarage
  attr_reader :small_available, :medium_available, :large_available

  SPOT_ORDER = {
    'small' => %i[small medium large],
    'medium' => %i[medium large],
    'large' => %i[large]
  }.freeze

  def initialize(small, medium, large)
    @small_available  = [small.to_i, 0].max
    @medium_available = [medium.to_i, 0].max
    @large_available  = [large.to_i, 0].max

    @spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)

    return 'Invalid license plate' if plate.nil? || plate.strip.empty?
    return 'Invalid car size' unless size

    SPOT_ORDER[size].each do |spot|
      next unless space_available_for?(size, spot)

      allocate_spot(spot, plate, size)
      decrement_spot_count(spot)
      return "car with license plate no. #{plate} is parked at #{spot}"
    end

    if size == 'large'
      return shuffle_large_for_large(plate, size)
    elsif size == 'medium'
      return shuffle_medium_for_medium(plate, size)
    end

    'No space available'
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Invalid license plate' if plate.nil? || plate.strip.empty?

    spot = @spots.find do |_spot_type, cars|
      cars.any? { |c| c[:plate] == plate }
    end

    return 'Car not found' unless spot

    spot_type, cars = spot
    car = cars.find { |c| c[:plate] == plate }
    cars.delete(car)
    increment_spot_count(spot_type)

    "car with license plate no. #{plate} exited"
  end

  def garage_summary
    {
      small_available: @small_available,
      medium_available: @medium_available,
      large_available: @large_available,
      total_occupied: total_capacity - total_available,
      total_available: total_available
    }
  end

  private

  def total_capacity
    @small_available_init + @medium_available_init + @large_available_init
  end

  def total_available
    @small_available + @medium_available + @large_available
  end

  def normalize_plate(plate)
    plate.nil? ? nil : plate.to_s.strip
  end

  def normalize_size(size)
    return nil if size.nil?

    normalized = size.to_s.strip.downcase
    return normalized if %w[small medium large].include?(normalized)

    nil
  end

  def allocate_spot(spot, plate, size)
    @spots[spot] << { plate: plate, size: size }
  end

  def decrement_spot_count(spot)
    case spot
    when :small then @small_available -= 1 if @small_available.positive?
    when :medium then @medium_available -= 1 if @medium_available.positive?
    when :large then @large_available -= 1 if @large_available.positive?
    end
  end

  def increment_spot_count(spot)
    case spot
    when :small then @small_available += 1
    when :medium then @medium_available += 1
    when :large then @large_available += 1
    end
  end

  def space_available_for?(car_size, spot)
    case spot
    when :small
      @small_available.positive?
    when :medium
      @medium_available.positive?
    when :large
      @large_available.positive?
    else
      false
    end
  end

  def shuffle_medium_for_medium(plate, size)
    return 'No space available' unless @large_available.positive?

    # Move a small car from medium to small if no medium spot but space in small
    if @medium_available.negative? || @medium_available.zero?
      victim = @spots[:medium].find { |c| c[:size] == 'small' }
      if victim && @small_available.positive?
        @spots[:medium].delete(victim)
        @spots[:small] << victim
        @small_available -= 1
        @medium_available += 1
      end
    end

    return 'No space available' unless @large_available.positive?

    allocate_spot(:large, plate, size)
    @large_available -= 1
    "car with license plate no. #{plate} is parked at large"
  end

  def shuffle_large_for_large(plate, size)
    victim = @spots[:large].find { |c| c[:size] == 'medium' }
    return 'No space available' unless victim && @medium_available.positive?

    @spots[:large].delete(victim)
    @spots[:medium] << victim
    @medium_available -= 1
    @large_available += 1

    allocate_spot(:large, plate, size)
    @large_available -= 1
    "car with license plate no. #{plate} is parked at large"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  GRACE_PERIOD_HOURS = 0.25
  MAX_DURATION_HOURS = 24.0

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.nil? ? nil : license_plate.to_s.strip
    normalized_size = car_size.nil? ? nil : car_size.to_s.strip.downcase
    @car_size = %w[small medium large].include?(normalized_size) ? normalized_size : nil
    @entry_time = entry_time
  end

  def duration_hours
    return 0.0 unless entry_time

    ((Time.now - entry_time) / 3600.0).round(2)
  end

  def valid?
    duration_hours <= MAX_DURATION_HOURS
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if invalid_input?(car_size, duration_hours)

    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    duration_hours = duration_hours.to_f
    return 0.0 if duration_hours <= GRACE_PERIOD

    billable_hours = (duration_hours - GRACE_PERIOD).ceil
    total = billable_hours * RATES[size]
    [total, MAX_FEE[size]].min
  end

  private

  def invalid_input?(car_size, duration_hours)
    car_size.nil? || duration_hours.nil? || !duration_hours.is_a?(Numeric) || duration_hours < 0
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(license_plate, car_size)
    plate = normalize_plate(license_plate)
    size = normalize_size(car_size)

    unless plate && !plate.strip.empty?
      return { success: false, message: 'Invalid license plate', ticket: nil }
    end

    unless size
      return { success: false, message: 'Invalid car size', ticket: nil }
    end

    message = garage.admit_car(plate, size)

    if message.start_with?('car with license plate')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message, ticket: nil }
    end
  end

  def exit_car(license_plate)
    plate = normalize_plate(license_plate)
    return { success: false, message: 'Invalid license plate', fee: nil, duration_hours: nil } if plate.nil? || plate.strip.empty?

    ticket = @active_tickets[plate]
    return { success: false, message: 'Ticket not found', fee: nil, duration_hours: nil } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    message = garage.exit_car(plate)
    @active_tickets.delete(plate)

    {
      success: message.start_with?('car with license plate'),
      message: message,
      fee: fee,
      duration_hours: ticket.duration_hours
    }
  end

  def garage_status
    summary = garage.garage_summary
    {
      small_available: summary[:small_available],
      medium_available: summary[:medium_available],
      large_available: summary[:large_available],
      total_available: summary[:total_available],
      total_occupied: summary[:total_occupied],
      active_tickets: @active_tickets.size
    }
  end

  def find_ticket(license_plate)
    return nil if license_plate.nil?

    @active_tickets[license_plate.to_s.strip]
  end

  private

  def normalize_plate(plate)
    plate.nil? ? nil : plate.to_s.strip
  end

  def normalize_size(size)
    return nil if size.nil?

    normalized = size.to_s.strip.downcase
    %w[small medium large].include?(normalized) ? normalized : nil
  end
end