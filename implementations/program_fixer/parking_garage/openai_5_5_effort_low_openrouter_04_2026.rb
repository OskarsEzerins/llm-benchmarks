require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze
  SPOT_KEYS = {
    'small' => :small_spot,
    'medium' => :medium_spot,
    'large' => :large_spot
  }.freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large = [large.to_i, 0].max

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)

    return 'No space available' if plate.nil? || size.nil?
    return 'No space available' if parked?(plate)

    car = { plate: plate, size: size }

    case size
    when 'small'
      park_in_first_available(car, %w[small medium large])
    when 'medium'
      park_in_first_available(car, %w[medium large])
    when 'large'
      if @large.positive?
        park_car(car, 'large')
      elsif shuffle_large
        park_car(car, 'large')
      else
        'No space available'
      end
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'No car found' if plate.nil?

    SPOT_KEYS.each do |spot_type, key|
      car = @parking_spots[key].find { |parked_car| parked_car[:plate] == plate }

      if car
        @parking_spots[key].delete(car)
        increment_available(spot_type)
        return exit_status(plate)
      end
    end

    'No car found'
  end

  def available_spots
    {
      small_available: @small,
      medium_available: @medium,
      large_available: @large
    }
  end

  def occupied_count
    @parking_spots.values.sum(&:size)
  end

  def total_available
    @small + @medium + @large
  end

  private

  def normalize_plate(license_plate_no)
    plate = license_plate_no.to_s.strip
    plate.empty? ? nil : plate
  end

  def normalize_size(car_size)
    size = car_size.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  end

  def parked?(plate)
    @parking_spots.values.flatten.any? { |car| car[:plate] == plate }
  end

  def park_in_first_available(car, spot_types)
    spot_types.each do |spot_type|
      return park_car(car, spot_type) if available_count(spot_type).positive?
    end

    'No space available'
  end

  def park_car(car, spot_type)
    key = SPOT_KEYS[spot_type]
    return 'No space available' unless key && available_count(spot_type).positive?

    @parking_spots[key] << car.merge(spot: spot_type)
    decrement_available(spot_type)
    parking_status(car, spot_type)
  end

  def shuffle_large
    small_in_large = @parking_spots[:large_spot].find { |car| car[:size] == 'small' }
    if small_in_large
      if @small.positive?
        move_car(small_in_large, 'large', 'small')
        return true
      elsif @medium.positive?
        move_car(small_in_large, 'large', 'medium')
        return true
      end
    end

    medium_in_large = @parking_spots[:large_spot].find { |car| car[:size] == 'medium' }
    if medium_in_large && @medium.positive?
      move_car(medium_in_large, 'large', 'medium')
      return true
    end

    false
  end

  def move_car(car, from_spot_type, to_spot_type)
    from_key = SPOT_KEYS[from_spot_type]
    to_key = SPOT_KEYS[to_spot_type]

    @parking_spots[from_key].delete(car)
    increment_available(from_spot_type)

    @parking_spots[to_key] << car.merge(spot: to_spot_type)
    decrement_available(to_spot_type)
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
    when 'small' then @small += 1
    when 'medium' then @medium += 1
    when 'large' then @large += 1
    end
  end

  def parking_status(car = nil, spot_type = nil)
    if car && spot_type
      "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : 'No car found'
  end
end

class ParkingTicket
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :id, :ticket_id, :entry_time, :license_plate, :license_plate_no, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @ticket_id = @id
    @license_plate = license_plate.to_s.strip
    @license_plate_no = @license_plate
    @car_size = normalize_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def normalize_size(car_size)
    size = car_size.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  end

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
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    duration = begin
      Float(duration_hours)
    rescue StandardError
      0.0
    end

    return 0.0 if duration <= GRACE_PERIOD_HOURS

    billable_hours = duration.ceil
    total = billable_hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **kwargs)
    small = kwargs.fetch(:small_spots, small_spots)
    medium = kwargs.fetch(:medium_spots, medium_spots)
    large = kwargs.fetch(:large_spots, large_spots)

    @garage = ParkingGarage.new(small || 0, medium || 0, large || 0)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    return failure('Invalid license plate') if normalized_plate.nil?
    return failure('Invalid car size') if normalized_size.nil?
    return failure('Car already parked') if @active_tickets.key?(normalized_plate)

    message = @garage.admit_car(normalized_plate, normalized_size)

    if message.include?('is parked at')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      failure(message)
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    return failure('Invalid license plate') if normalized_plate.nil?

    ticket = @active_tickets[normalized_plate]
    return failure('No active ticket found') unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    if message.include?('exited')
      @active_tickets.delete(normalized_plate)
      {
        success: true,
        message: message,
        fee: fee.to_f,
        duration_hours: duration
      }
    else
      failure(message)
    end
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.occupied_count,
      total_available: @garage.total_available
    }
  end

  def find_ticket(plate)
    normalized_plate = normalize_plate(plate)
    return nil if normalized_plate.nil?

    @active_tickets[normalized_plate]
  end

  private

  def normalize_plate(plate)
    normalized = plate.to_s.strip
    normalized.empty? ? nil : normalized
  end

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    %w[small medium large].include?(normalized) ? normalized : nil
  end

  def failure(message)
    { success: false, message: message }
  end
end