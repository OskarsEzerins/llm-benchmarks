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

    return 'Invalid license plate number' if plate.nil?
    return 'Invalid car size' if size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      return park_in(car, 'small') if @small.positive?
      return park_in(car, 'medium') if @medium.positive?
      return park_in(car, 'large') if @large.positive?
      parking_status
    when 'medium'
      return park_in(car, 'medium') if @medium.positive?
      return park_in(car, 'large') if @large.positive?
      shuffle_medium(car)
    when 'large'
      return park_in(car, 'large') if @large.positive?
      shuffle_large(car)
    else
      'Invalid car size'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Invalid license plate number' if plate.nil?

    %w[small medium large].each do |spot_size|
      key = SPOT_KEYS[spot_size]
      car = @parking_spots[key].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[key].delete(car)
      increment_count(spot_size)
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    if @small.positive?
      victim = @parking_spots[:medium_spot].find { |c| c[:size] == 'small' }
      if victim
        move_car(victim, 'medium', 'small')
        return park_in(car, 'medium')
      end

      victim = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
      if victim
        move_car(victim, 'large', 'small')
        return park_in(car, 'large')
      end
    end

    parking_status
  end

  def shuffle_large(car)
    if @medium.positive?
      victim = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
      if victim
        move_car(victim, 'large', 'medium')
        return park_in(car, 'large')
      end
    end

    if @small.positive?
      victim = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
      if victim
        move_car(victim, 'large', 'small')
        return park_in(car, 'large')
      end
    end

    if @medium.positive?
      victim = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
      if victim
        move_car(victim, 'large', 'medium')
        return park_in(car, 'large')
      end
    end

    parking_status
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      'Car not found'
    end
  end

  private

  def normalize_plate(plate)
    normalized = plate.to_s.strip
    normalized.empty? ? nil : normalized
  end

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    VALID_SIZES.include?(normalized) ? normalized : nil
  end

  def park_in(car, spot_size)
    @parking_spots[SPOT_KEYS[spot_size]] << car
    decrement_count(spot_size)
    parking_status(car, spot_size)
  end

  def move_car(car, from_size, to_size)
    @parking_spots[SPOT_KEYS[from_size]].delete(car)
    increment_count(from_size)
    @parking_spots[SPOT_KEYS[to_size]] << car
    decrement_count(to_size)
  end

  def decrement_count(spot_size)
    case spot_size
    when 'small' then @small -= 1
    when 'medium' then @medium -= 1
    when 'large' then @large -= 1
    end
  end

  def increment_count(spot_size)
    case spot_size
    when 'small' then @small += 1
    when 'medium' then @medium += 1
    when 'large' then @large += 1
    end
  end
end

class ParkingTicket
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :id, :entry_time, :car_size, :license_plate

  alias ticket_id id
  alias license_plate_no license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s.strip
    @car_size = normalize_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).to_f
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    SecureRandom.uuid
  end

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    VALID_SIZES.include?(normalized) ? normalized : normalized.to_s
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
    size = normalize_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 if size.nil? || duration.nil?
    return 0.0 if duration <= 0.0
    return 0.0 if duration <= 0.25

    full_days = (duration / 24.0).floor
    remainder = duration - (full_days * 24.0)

    total = full_days * MAX_FEE[size]
    if remainder.positive?
      total += [remainder.ceil * RATES[size], MAX_FEE[size]].min
    end

    total.to_f
  end

  private

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    RATES.key?(normalized) ? normalized : nil
  end

  def normalize_duration(duration)
    value = Float(duration)
    return nil unless value.finite?

    value
  rescue ArgumentError, TypeError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(*args, **kwargs)
    if kwargs.any?
      small = kwargs[:small_spots] || kwargs[:small] || args[0]
      medium = kwargs[:medium_spots] || kwargs[:medium] || args[1]
      large = kwargs[:large_spots] || kwargs[:large] || args[2]
    else
      small, medium, large = args
    end

    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    return { success: false, message: 'Invalid license plate number' } if normalized_plate.nil?
    return { success: false, message: 'Invalid car size' } if normalized_size.nil?
    return { success: false, message: 'Car already parked' } if @active_tickets.key?(normalized_plate)

    result = @garage.admit_car(normalized_plate, normalized_size)

    if parked_message?(result)
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    return { success: false, message: 'Invalid license plate number' } if normalized_plate.nil?

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(normalized_plate)

    if exited_message?(result)
      @active_tickets.delete(normalized_plate)
      {
        success: true,
        message: result,
        fee: fee.to_f,
        duration_hours: duration.to_f
      }
    else
      {
        success: false,
        message: result,
        fee: fee.to_f,
        duration_hours: duration.to_f
      }
    end
  end

  def garage_status
    small_available = @garage.small
    medium_available = @garage.medium
    large_available = @garage.large
    total_available = small_available + medium_available + large_available
    total_occupied = @garage.parking_spots.values.sum(&:size)

    {
      small_available: small_available,
      medium_available: medium_available,
      large_available: large_available,
      total_occupied: total_occupied,
      total_available: total_available
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

  def parked_message?(message)
    message.to_s.include?('is parked at')
  end

  def exited_message?(message)
    message.to_s.include?('exited')
  end
end