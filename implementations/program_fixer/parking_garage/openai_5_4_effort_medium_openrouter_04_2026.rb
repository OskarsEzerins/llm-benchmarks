require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  VALID_SIZES = %w[small medium large].freeze

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

    return 'No space available' if plate.nil? || size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      return park_car(car, :small) if @small.positive?
      return park_car(car, :medium) if @medium.positive?
      return park_car(car, :large) if @large.positive?
    when 'medium'
      return park_car(car, :medium) if @medium.positive?
      return park_car(car, :large) if @large.positive?
      return park_car(car, :medium) if free_spot(:medium)
      return park_car(car, :large) if free_spot(:large)
    when 'large'
      return park_car(car, :large) if @large.positive?
      return park_car(car, :large) if free_spot(:large)
    end

    'No space available'
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Car not found' if plate.nil?

    [:small, :medium, :large].each do |spot_type|
      car = @parking_spots[spot_type].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot_type].delete(car)
      increment_available(spot_type)
      return exit_status(plate)
    end

    'Car not found'
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    return 'Car not found' if plate.nil?

    "car with license plate no. #{plate} exited"
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    normalized = plate.to_s.strip
    normalized.empty? ? nil : normalized
  end

  def normalize_size(size)
    return nil if size.nil?

    normalized = size.to_s.strip.downcase
    VALID_SIZES.include?(normalized) ? normalized : nil
  end

  def park_car(car, spot_type)
    decrement_available(spot_type)
    car[:parked_at] = spot_type.to_s
    @parking_spots[spot_type] << car
    parking_status(car, spot_type.to_s)
  end

  def free_spot(spot_type)
    return false if available_count(spot_type).positive?
    return false if spot_type == :small

    @parking_spots[spot_type].dup.each do |car|
      relocation_targets(car, spot_type).each do |target|
        if available_count(target).positive? || free_spot(target)
          move_car(car, spot_type, target)
          return true
        end
      end
    end

    false
  end

  def relocation_targets(car, current_spot)
    case car[:size]
    when 'small'
      case current_spot
      when :large then [:small, :medium]
      when :medium then [:small]
      else []
      end
    when 'medium'
      current_spot == :large ? [:medium] : []
    else
      []
    end
  end

  def move_car(car, from_spot, to_spot)
    @parking_spots[from_spot].delete(car)
    increment_available(from_spot)
    decrement_available(to_spot)
    car[:parked_at] = to_spot.to_s
    @parking_spots[to_spot] << car
  end

  def available_count(spot_type)
    case spot_type
    when :small then @small
    when :medium then @medium
    when :large then @large
    else 0
    end
  end

  def decrement_available(spot_type)
    case spot_type
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
  end

  def increment_available(spot_type)
    case spot_type
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  VALID_SIZES = %w[small medium large].freeze

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = normalize_plate(license_plate)
    @car_size = normalize_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours(current_time = Time.now)
    current = current_time.is_a?(Time) ? current_time : Time.now
    duration = (current - @entry_time) / 3600.0
    duration.negative? ? 0.0 : duration
  end

  def valid?(current_time = Time.now)
    duration_hours(current_time) <= 24.0
  end

  private

  def generate_ticket_id
    SecureRandom.uuid
  end

  def normalize_plate(plate)
    return '' if plate.nil?

    plate.to_s.strip
  end

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    VALID_SIZES.include?(normalized) ? normalized : ''
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
    return 0.0 if duration <= 0.25

    hours = duration.ceil
    total = hours * RATES[size]
    [total.to_f, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    RATES.key?(normalized) ? normalized : nil
  end

  def normalize_duration(duration)
    value = begin
      Float(duration)
    rescue StandardError
      nil
    end

    return nil if value.nil? || value.negative?

    value
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  VALID_SIZES = %w[small medium large].freeze

  def initialize(*args, small_spots: nil, medium_spots: nil, large_spots: nil)
    if args.length == 3
      small_spots, medium_spots, large_spots = args
    end

    @garage = ParkingGarage.new(small_spots || 0, medium_spots || 0, large_spots || 0)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    return { success: false, message: 'Invalid license plate', ticket: nil } if normalized_plate.nil?
    return { success: false, message: 'Invalid car size', ticket: nil } if normalized_size.nil?
    return { success: false, message: 'Car already parked', ticket: @active_tickets[normalized_plate] } if @active_tickets.key?(normalized_plate)

    message = @garage.admit_car(normalized_plate, normalized_size)

    if parked_message?(message)
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message, ticket: nil }
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    return { success: false, message: 'Ticket not found' } if normalized_plate.nil?

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    if exited_message?(message)
      @active_tickets.delete(normalized_plate)
      {
        success: true,
        message: message,
        fee: fee.to_f,
        duration_hours: duration
      }
    else
      {
        success: false,
        message: message,
        fee: 0.0,
        duration_hours: duration
      }
    end
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large
    total_occupied = @garage.parking_spots.values.map(&:size).sum

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
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
    return nil if plate.nil?

    normalized = plate.to_s.strip
    normalized.empty? ? nil : normalized
  end

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    VALID_SIZES.include?(normalized) ? normalized : nil
  end

  def parked_message?(message)
    message.is_a?(String) && message.include?('is parked at')
  end

  def exited_message?(message)
    message.is_a?(String) && message.include?('exited')
  end
end