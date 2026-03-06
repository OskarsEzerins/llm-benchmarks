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
        @parking_spots[:small] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium.positive?
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large.positive?
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        'No space available'
      end
    when 'medium'
      if @medium.positive?
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large.positive?
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        'No space available'
      end
    when 'large'
      if @large.positive?
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car)
      end
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Car not found' if plate.nil?

    small_car = @parking_spots[:small].find { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate }
    large_car = @parking_spots[:large].find { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      exit_status(plate)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      exit_status(plate)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      exit_status(plate)
    else
      'Car not found'
    end
  end

  def shuffle_medium(_car)
    'No space available'
  end

  def shuffle_large(car)
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    small_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }

    if medium_in_large && @medium.positive?
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium -= 1
      @large += 1
      @parking_spots[:large] << car
      @large -= 1
      return parking_status(car, 'large')
    end

    if small_in_medium && @small.positive?
      @parking_spots[:medium].delete(small_in_medium)
      @parking_spots[:small] << small_in_medium
      @small -= 1
      @medium += 1

      @parking_spots[:medium] << car
      @medium -= 1
      return parking_status(car, 'medium')
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
    plate ? "car with license plate no. #{plate} exited" : 'Car not found'
  end

  private

  def normalize_plate(plate)
    str = plate.to_s.strip
    str.empty? ? nil : str
  end

  def normalize_size(size)
    str = size.to_s.strip.downcase
    VALID_SIZES.include?(str) ? str : nil
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  VALID_SIZES = %w[small medium large].freeze

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s.strip
    normalized_size = car_size.to_s.strip.downcase
    @car_size = VALID_SIZES.include?(normalized_size) ? normalized_size : nil
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [(Time.now - entry_time) / 3600.0, 0.0].max
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
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    hours = begin
      Float(duration_hours)
    rescue StandardError
      nil
    end
    return 0.0 if hours.nil? || hours <= 0.0
    return 0.0 if hours <= 0.25

    billable_hours = hours.ceil
    total = billable_hours * RATES[size]
    [total.to_f, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(*args, **kwargs)
    if kwargs.empty?
      small_spots, medium_spots, large_spots = args
    else
      small_spots = kwargs[:small_spots]
      medium_spots = kwargs[:medium_spots]
      large_spots = kwargs[:large_spots]
    end

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    return { success: false, message: 'Invalid license plate', ticket: nil } if normalized_plate.nil?
    return { success: false, message: 'Invalid car size', ticket: nil } if normalized_size.nil?
    return { success: false, message: 'Car already parked', ticket: @tix_in_flight[normalized_plate] } if @tix_in_flight.key?(normalized_plate)

    verdict = @garage.admit_car(normalized_plate, normalized_size)

    if verdict.include?('is parked at')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @tix_in_flight[normalized_plate] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict, ticket: nil }
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    return { success: false, message: 'Car not found', fee: 0.0, duration_hours: 0.0 } if normalized_plate.nil?

    ticket = @tix_in_flight[normalized_plate]
    return { success: false, message: 'Car not found', fee: 0.0, duration_hours: 0.0 } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(normalized_plate)

    @tix_in_flight.delete(normalized_plate)
    { success: true, message: result, fee: fee.to_f, duration_hours: duration.to_f }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @tix_in_flight.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tix_in_flight[normalize_plate(plate)]
  end

  private

  def normalize_plate(plate)
    str = plate.to_s.strip
    str.empty? ? nil : str
  end

  def normalize_size(size)
    str = size.to_s.strip.downcase
    %w[small medium large].include?(str) ? str : nil
  end
end