require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  VALID_SIZES = %w[small medium large].freeze

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
      park_small_car(car)
    when 'medium'
      park_medium_car(car)
    when 'large'
      park_large_car(car)
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'No car found' if plate.nil?

    @parking_spots.each do |spot_type, cars|
      car = cars.find { |vehicle| vehicle[:plate] == plate }
      next unless car

      cars.delete(car)
      increment_available(spot_type)
      return "car with license plate no. #{plate} exited"
    end

    'No car found'
  end

  private

  def park_small_car(car)
    if @small.positive?
      add_car(car, :small_spot)
      parking_status(car, 'small')
    elsif @medium.positive?
      add_car(car, :medium_spot)
      parking_status(car, 'medium')
    elsif @large.positive?
      add_car(car, :large_spot)
      parking_status(car, 'large')
    else
      'No space available'
    end
  end

  def park_medium_car(car)
    if @medium.positive?
      add_car(car, :medium_spot)
      parking_status(car, 'medium')
    elsif @large.positive?
      add_car(car, :large_spot)
      parking_status(car, 'large')
    elsif make_medium_space
      add_car(car, :medium_spot)
      parking_status(car, 'medium')
    else
      'No space available'
    end
  end

  def park_large_car(car)
    if @large.positive?
      add_car(car, :large_spot)
      return parking_status(car, 'large')
    end

    if shuffle_large
      add_car(car, :large_spot)
      parking_status(car, 'large')
    else
      'No space available'
    end
  end

  def shuffle_large
    medium_car = @parking_spots[:large_spot].find { |car| car[:size] == 'medium' }
    if medium_car && make_medium_space
      move_car(medium_car, :large_spot, :medium_spot)
      return true
    end

    small_car = @parking_spots[:large_spot].find { |car| car[:size] == 'small' }
    return false unless small_car

    if @small.positive?
      move_car(small_car, :large_spot, :small_spot)
      true
    elsif make_medium_space
      move_car(small_car, :large_spot, :medium_spot)
      true
    else
      false
    end
  end

  def make_medium_space
    return true if @medium.positive?
    return false unless @small.positive?

    small_car = @parking_spots[:medium_spot].find { |car| car[:size] == 'small' }
    return false unless small_car

    move_car(small_car, :medium_spot, :small_spot)
    true
  end

  def add_car(car, spot_type)
    @parking_spots[spot_type] << car
    decrement_available(spot_type)
  end

  def move_car(car, from_spot, to_spot)
    @parking_spots[from_spot].delete(car)
    increment_available(from_spot)
    @parking_spots[to_spot] << car
    decrement_available(to_spot)
  end

  def decrement_available(spot_type)
    case spot_type
    when :small_spot then @small -= 1
    when :medium_spot then @medium -= 1
    when :large_spot then @large -= 1
    end
  end

  def increment_available(spot_type)
    case spot_type
    when :small_spot then @small += 1
    when :medium_spot then @medium += 1
    when :large_spot then @large += 1
    end
  end

  def parked?(plate)
    @parking_spots.values.flatten.any? { |car| car[:plate] == plate }
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

  def parking_status(car, space)
    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    duration_hours <= 24.0
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

    duration = Float(duration_hours)
    return 0.0 unless duration.finite? && duration >= 0.0
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    hours = duration.ceil
    [(hours * RATES[size]).to_f, MAX_FEE[size]].min.to_f
  rescue ArgumentError, TypeError
    0.0
  end
end

class ParkingGarageManager
  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **options)
    small_spots = options[:small_spots] if options.key?(:small_spots)
    medium_spots = options[:medium_spots] if options.key?(:medium_spots)
    large_spots = options[:large_spots] if options.key?(:large_spots)

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    return failure('No space available') if normalized_plate.nil? || normalized_size.nil?
    return failure('car already parked') if @tix_in_flight.key?(normalized_plate)

    result = @garage.admit_car(normalized_plate, normalized_size)

    if result.include?('is parked at')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @tix_in_flight[normalized_plate] = ticket
      {
        success: true,
        message: result,
        ticket: ticket
      }
    else
      failure(result)
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    ticket = normalized_plate && @tix_in_flight[normalized_plate]
    return failure('No active ticket found') unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(normalized_plate)

    unless result.include?(' exited')
      return failure(result)
    end

    @tix_in_flight.delete(normalized_plate)

    {
      success: true,
      message: result,
      fee: fee,
      duration_hours: duration
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
    normalized_plate = normalize_plate(plate)
    normalized_plate ? @tix_in_flight[normalized_plate] : nil
  end

  private

  def failure(message)
    { success: false, message: message.to_s }
  end

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