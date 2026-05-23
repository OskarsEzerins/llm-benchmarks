require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

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

    return no_space_message if plate.nil? || size.nil?
    return no_space_message if parked?(plate)

    car = { plate: plate, size: size }

    case size
    when 'small'
      park_in_first_available(car, %i[small medium large])
    when 'medium'
      park_in_first_available(car, %i[medium large])
    when 'large'
      park_large_car(car)
    else
      no_space_message
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return not_found_message if plate.nil?

    spot_type, car = find_car_with_spot(plate)
    return not_found_message unless car

    @parking_spots[spot_type].delete(car)
    increment_available(spot_type)

    exit_status(plate)
  end

  def occupied_count
    @parking_spots.values.sum(&:size)
  end

  def available_count
    @small + @medium + @large
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

  def parked?(plate)
    @parking_spots.values.any? { |cars| cars.any? { |car| car[:plate] == plate } }
  end

  def park_in_first_available(car, spot_types)
    spot_types.each do |spot_type|
      next unless available_for?(spot_type).positive?

      park_in_spot(car, spot_type)
      return parking_status(car, spot_type.to_s)
    end

    no_space_message
  end

  def park_large_car(car)
    if @large.positive?
      park_in_spot(car, :large)
      return parking_status(car, 'large')
    end

    return parking_status(car, 'large') if shuffle_for_large_car(car)

    no_space_message
  end

  def shuffle_for_large_car(large_car)
    victim_info = find_large_spot_victim
    return false unless victim_info

    victim, destination = victim_info

    @parking_spots[:large].delete(victim)
    increment_available(:large)

    park_in_spot(victim, destination)

    park_in_spot(large_car, :large)
    true
  end

  def find_large_spot_victim
    @parking_spots[:large].each do |car|
      case car[:size]
      when 'small'
        return [car, :small] if @small.positive?
        return [car, :medium] if @medium.positive?
      when 'medium'
        return [car, :medium] if @medium.positive?
      end
    end

    nil
  end

  def park_in_spot(car, spot_type)
    @parking_spots[spot_type] << car
    decrement_available(spot_type)
    car[:spot] = spot_type.to_s
  end

  def available_for?(spot_type)
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

  def find_car_with_spot(plate)
    @parking_spots.each do |spot_type, cars|
      car = cars.find { |parked_car| parked_car[:plate] == plate }
      return [spot_type, car] if car
    end

    [nil, nil]
  end

  def parking_status(car = nil, space = nil)
    return no_space_message unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    return not_found_message if plate.nil?

    "car with license plate no. #{plate} exited"
  end

  def no_space_message
    'No space available'
  end

  def not_found_message
    'Car not found'
  end
end

class ParkingTicket
  attr_reader :id, :ticket_id, :entry_time, :license_plate, :license_plate_no, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @ticket_id = @id
    @license_plate = license_plate.to_s.strip
    @license_plate_no = @license_plate
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(4)
  end

  def valid?
    duration_hours <= 24.0
  end

  private

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
    size = normalize_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 unless size
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    billable_hours = duration.ceil
    fee = billable_hours * RATES[size]

    [fee, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    RATES.key?(normalized) ? normalized : nil
  end

  def normalize_duration(duration)
    Float(duration)
  rescue StandardError
    0.0
  else
    value = Float(duration)
    value.negative? ? 0.0 : value
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(*args, small_spots: nil, medium_spots: nil, large_spots: nil)
    if args.length == 3
      small_spots, medium_spots, large_spots = args
    end

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    return failure('Invalid license plate') unless normalized_plate
    return failure('Invalid car size') unless normalized_size
    return failure('Car already parked') if @active_tickets.key?(normalized_plate)

    message = @garage.admit_car(normalized_plate, normalized_size)

    if message.include?('is parked at')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket

      {
        success: true,
        message: message,
        ticket: ticket
      }
    else
      failure(message)
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    return failure('Ticket not found') unless normalized_plate

    ticket = @active_tickets[normalized_plate]
    return failure('Ticket not found') unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)
    @active_tickets.delete(normalized_plate)

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
      total_occupied: @garage.occupied_count,
      total_available: @garage.available_count
    }
  end

  def find_ticket(plate)
    normalized_plate = normalize_plate(plate)
    return nil unless normalized_plate

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
    {
      success: false,
      message: message
    }
  end
end