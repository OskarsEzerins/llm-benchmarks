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
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car) || parking_status
      end
    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Car not found' if plate.nil?

    [:small, :medium, :large].each do |spot_type|
      car = @parking_spots[spot_type].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot_type].delete(car)
      case spot_type
      when :small then @small += 1
      when :medium then @medium += 1
      when :large then @large += 1
      end
      return exit_status(plate)
    end

    'Car not found'
  end

  def shuffle_large(car)
    return nil unless @large.zero?

    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium > 0
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium -= 1
      @parking_spots[:large] << car
      return parking_status(car, 'large')
    end

    small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if small_in_large
      if @small > 0
        @parking_spots[:large].delete(small_in_large)
        @parking_spots[:small] << small_in_large
        @small -= 1
        @parking_spots[:large] << car
        return parking_status(car, 'large')
      elsif @medium > 0
        @parking_spots[:large].delete(small_in_large)
        @parking_spots[:medium] << small_in_large
        @medium -= 1
        @parking_spots[:large] << car
        return parking_status(car, 'large')
      end
    end

    nil
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

  def normalize_plate(license_plate_no)
    return nil if license_plate_no.nil?

    plate = license_plate_no.to_s.strip
    return nil if plate.empty?

    plate
  end

  def normalize_size(car_size)
    return nil if car_size.nil?

    size = car_size.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  end
end

class ParkingTicket
  attr_reader :id, :ticket_id, :entry_time, :car_size, :license_plate, :license_plate_no

  VALID_SIZES = %w[small medium large].freeze

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @ticket_id = @id
    @license_plate = license_plate.to_s
    @license_plate_no = @license_plate
    normalized_size = car_size.to_s.strip.downcase
    @car_size = VALID_SIZES.include?(normalized_size) ? normalized_size : normalized_size
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    duration = (Time.now - @entry_time) / 3600.0
    duration.negative? ? 0.0 : duration
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

    hours = begin
      Float(duration_hours)
    rescue StandardError
      nil
    end
    return 0.0 if hours.nil? || hours.negative?
    return 0.0 if hours <= GRACE_PERIOD_HOURS

    billable_hours = hours.ceil
    total = billable_hours * RATES[size]
    [total.to_f, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(*args, **kwargs)
    if kwargs.any?
      small_spots = kwargs[:small_spots]
      medium_spots = kwargs[:medium_spots]
      large_spots = kwargs[:large_spots]
    else
      small_spots, medium_spots, large_spots = args
    end

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
    @tix_in_flight = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    return { success: false, message: 'Invalid input', ticket: nil } if normalized_plate.nil? || normalized_size.nil?
    return { success: false, message: 'Car already admitted', ticket: @active_tickets[normalized_plate] } if @active_tickets.key?(normalized_plate)

    verdict = @garage.admit_car(normalized_plate, normalized_size)

    if verdict.include?('is parked at')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict, ticket: nil }
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    return { success: false, message: 'Car not found' } if normalized_plate.nil?

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'Car not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(normalized_plate)

    @active_tickets.delete(normalized_plate)

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
      total_occupied: @active_tickets.size,
      total_available: @garage.small + @garage.medium + @garage.large
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

    value = plate.to_s.strip
    return nil if value.empty?

    value
  end

  def normalize_size(size)
    value = size.to_s.strip.downcase
    %w[small medium large].include?(value) ? value : nil
  end
end