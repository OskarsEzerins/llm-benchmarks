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
      if @small.positive?
        park(car, :small)
      elsif @medium.positive?
        park(car, :medium)
      elsif @large.positive?
        park(car, :large)
      else
        'No space available'
      end
    when 'medium'
      if @medium.positive?
        park(car, :medium)
      elsif @large.positive?
        park(car, :large)
      else
        shuffle_medium(car)
      end
    when 'large'
      if @large.positive?
        park(car, :large)
      else
        shuffle_large(car)
      end
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'No car found' if plate.nil?

    @parking_spots.each do |spot_type, cars|
      car = cars.find { |item| item[:plate] == plate }
      next unless car

      cars.delete(car)
      increment_available(spot_type)
      return "car with license plate no. #{plate} exited"
    end

    'No car found'
  end

  def shuffle_medium(car)
    return park(car, :medium) if @medium.positive?
    return park(car, :large) if @large.positive?

    if @small.positive?
      victim = @parking_spots[:medium].find { |item| item[:size] == 'small' }

      if victim
        @parking_spots[:medium].delete(victim)
        @medium += 1
        park(car, :medium)
        return "car with license plate no. #{car[:plate]} is parked at medium"
      end
    end

    'No space available'
  end

  def shuffle_large(car)
    return park(car, :large) if @large.positive?

    victim = @parking_spots[:large].find { |item| item[:size] == 'medium' }

    if victim && @medium.positive?
      @parking_spots[:large].delete(victim)
      @medium += 1
      @parking_spots[:medium] << victim
      @medium -= 1
      @parking_spots[:large] << car
      @large -= 1
      return "car with license plate no. #{car[:plate]} is parked at large"
    end

    'No space available'
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : 'No car found'
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    value = plate.to_s.strip
    value.empty? ? nil : value
  end

  def normalize_size(size)
    return nil if size.nil?

    value = size.to_s.downcase.strip
    VALID_SIZES.include?(value) ? value : nil
  end

  def park(car, spot_type)
    @parking_spots[spot_type] << car
    decrement_available(spot_type)
    parking_status(car, spot_type.to_s)
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

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.nil? ? nil : license_plate.to_s
    @car_size = normalize_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    duration = (Time.now - @entry_time) / 3600.0
    duration.negative? ? 0.0 : duration.to_f
  end

  def valid?
    !@license_plate.nil? &&
      !@car_size.nil? &&
      duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
  end

  def normalize_size(size)
    return nil if size.nil?

    value = size.to_s.downcase.strip
    %w[small medium large].include?(value) ? value : nil
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
    size = car_size.nil? ? nil : car_size.to_s.downcase.strip
    duration = parse_duration(duration_hours)

    return 0.0 unless RATES.key?(size)
    return 0.0 if duration.nil? || duration <= GRACE_PERIOD

    hours = duration.ceil
    [hours * RATES[size], MAX_FEE[size]].min.to_f
  end

  private

  def parse_duration(value)
    duration =
      if value.is_a?(Numeric)
        value.to_f
      elsif value.respond_to?(:to_f)
        value.to_f
      end

    return nil unless duration && duration.finite?
    return nil if duration.negative?

    duration
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **options)
    small_spots = options[:small_spots] if small_spots.nil?
    medium_spots = options[:medium_spots] if medium_spots.nil?
    large_spots = options[:large_spots] if large_spots.nil?

    @garage = ParkingGarage.new(small_spots || 0, medium_spots || 0, large_spots || 0)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    if normalized_plate.nil? || normalized_size.nil?
      return { success: false, message: 'No space available' }
    end

    if @tix_in_flight.key?(normalized_plate)
      return { success: false, message: 'Car is already parked' }
    end

    message = @garage.admit_car(normalized_plate, normalized_size)

    unless message.include?('is parked')
      return { success: false, message: message }
    end

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @tix_in_flight[normalized_plate] = ticket

    {
      success: true,
      message: message,
      ticket: ticket
    }
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    ticket = @tix_in_flight[normalized_plate]

    return { success: false, message: 'No active ticket' } unless ticket
    return { success: false, message: 'Invalid or expired ticket' } unless ticket.valid?

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(normalized_plate)

    if result.include?('exited')
      @tix_in_flight.delete(normalized_plate)
      {
        success: true,
        message: result,
        fee: fee.to_f,
        duration_hours: duration.to_f
      }
    else
      { success: false, message: result }
    end
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
    @tix_in_flight[normalize_plate(plate)]
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    value = plate.to_s.strip
    value.empty? ? nil : value
  end

  def normalize_size(size)
    return nil if size.nil?

    value = size.to_s.downcase.strip
    %w[small medium large].include?(value) ? value : nil
  end
end