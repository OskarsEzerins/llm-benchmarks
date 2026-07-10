require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  VALID_SIZES = %w[small medium large].freeze

  def initialize(small, medium, large)
    @small = normalized_capacity(small)
    @medium = normalized_capacity(medium)
    @large = normalized_capacity(large)

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
    return 'No space available' if car_already_parked?(plate)

    car = { plate: plate, size: size }
    preferred_spot = preferred_spots_for(size).find { |spot| available?(spot) }

    if preferred_spot
      park_car(car, preferred_spot)
      return parking_status(car, preferred_spot)
    end

    case size
    when 'medium'
      shuffle_medium(car)
    when 'large'
      shuffle_large(car)
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status unless plate

    @parking_spots.each do |spot_type, cars|
      car = cars.find { |parked_car| parked_car[:plate] == plate }
      next unless car

      cars.delete(car)
      increase_available(spot_type)
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    return 'No space available' unless available?(:small)

    source_spot = %i[medium large].find do |spot|
      @parking_spots[spot].any? { |parked_car| parked_car[:size] == 'small' }
    end

    return 'No space available' unless source_spot

    small_car = @parking_spots[source_spot].find { |parked_car| parked_car[:size] == 'small' }
    move_car(small_car, source_spot, :small)
    park_car(car, source_spot)

    parking_status(car, source_spot)
  end

  def shuffle_large(car)
    large_cars = @parking_spots[:large]

    candidate = large_cars.find do |parked_car|
      destination = relocation_destination(parked_car[:size])
      !destination.nil?
    end

    return 'No space available' unless candidate

    destination = relocation_destination(candidate[:size])
    move_car(candidate, :large, destination)
    park_car(car, :large)

    parking_status(car, :large)
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    return 'No car found' if plate.nil?

    "car with license plate no. #{plate} exited"
  end

  private

  def normalized_capacity(value)
    [Integer(value), 0].max
  rescue ArgumentError, TypeError
    0
  end

  def normalize_plate(plate)
    return nil if plate.nil?

    value = plate.to_s.strip
    value.empty? ? nil : value
  end

  def normalize_size(size)
    return nil if size.nil?

    value = size.to_s.strip.downcase
    VALID_SIZES.include?(value) ? value : nil
  end

  def preferred_spots_for(size)
    case size
    when 'small' then %i[small medium large]
    when 'medium' then %i[medium large]
    when 'large' then %i[large]
    else []
    end
  end

  def relocation_destination(size)
    case size
    when 'small'
      return :small if available?(:small)
      return :medium if available?(:medium)
    when 'medium'
      return :medium if available?(:medium)
    end

    nil
  end

  def car_already_parked?(plate)
    @parking_spots.values.flatten.any? { |car| car[:plate] == plate }
  end

  def available?(spot_type)
    available_count(spot_type).positive?
  end

  def available_count(spot_type)
    case spot_type
    when :small then @small
    when :medium then @medium
    when :large then @large
    else 0
    end
  end

  def decrease_available(spot_type)
    case spot_type
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
  end

  def increase_available(spot_type)
    case spot_type
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end
  end

  def park_car(car, spot_type)
    @parking_spots[spot_type] << car
    decrease_available(spot_type)
  end

  def move_car(car, from_spot, to_spot)
    @parking_spots[from_spot].delete(car)
    increase_available(from_spot)
    @parking_spots[to_spot] << car
    decrease_available(to_spot)
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

  def license_plate_no
    @license_plate
  end

  def duration_hours
    duration = (Time.now - @entry_time) / 3600.0
    [duration, 0.0].max
  rescue StandardError
    0.0
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
  end

  def normalize_plate(plate)
    return nil if plate.nil?

    value = plate.to_s.strip
    value.empty? ? nil : value
  end

  def normalize_size(size)
    return nil if size.nil?

    value = size.to_s.strip.downcase
    VALID_SIZES.include?(value) ? value : nil
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

    return 0.0 if size.nil? || duration.nil?
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    hours = duration.ceil
    fee = hours * RATES[size]

    [fee, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_size(size)
    return nil if size.nil?

    value = size.to_s.strip.downcase
    RATES.key?(value) ? value : nil
  end

  def normalize_duration(duration)
    value = Float(duration)
    return nil unless value.finite?
    return nil if value.negative?

    value
  rescue ArgumentError, TypeError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage, :active_tickets

  def initialize(*args, small_spots: nil, medium_spots: nil, large_spots: nil)
    if args.any?
      small_spots, medium_spots, large_spots = args
    end

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    if normalized_plate.nil? || normalized_size.nil?
      return { success: false, message: 'No space available' }
    end

    if @active_tickets.key?(normalized_plate)
      return { success: false, message: 'No space available' }
    end

    message = @garage.admit_car(normalized_plate, normalized_size)

    unless message.include?('is parked at')
      return { success: false, message: message }
    end

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @active_tickets[normalized_plate] = ticket

    {
      success: true,
      message: message,
      ticket: ticket
    }
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    ticket = normalized_plate && @active_tickets[normalized_plate]

    return { success: false, message: 'No active ticket found' } unless ticket

    message = @garage.exit_car(normalized_plate)

    unless message.include?(' exited')
      return { success: false, message: message }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    @active_tickets.delete(normalized_plate)

    {
      success: true,
      message: message,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.parking_spots.values.sum(&:size),
      total_available: total_available
    }
  end

  def find_ticket(plate)
    normalized_plate = normalize_plate(plate)
    normalized_plate ? @active_tickets[normalized_plate] : nil
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    value = plate.to_s.strip
    value.empty? ? nil : value
  end

  def normalize_size(size)
    return nil if size.nil?

    value = size.to_s.strip.downcase
    ParkingGarage::VALID_SIZES.include?(value) ? value : nil
  end
end