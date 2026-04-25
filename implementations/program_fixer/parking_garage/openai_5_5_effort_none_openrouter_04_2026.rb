require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large  = [large.to_i, 0].max

    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)

    return 'No space available' if plate.nil? || size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      park_in_first_available(car, %w[small medium large])
    when 'medium'
      park_in_first_available(car, %w[medium large])
    when 'large'
      park_large_car(car)
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'car not found' if plate.nil?

    %i[small medium large].each do |spot_type|
      car = @parking_spots[spot_type].find { |parked_car| parked_car[:plate] == plate }
      next unless car

      @parking_spots[spot_type].delete(car)
      increment_available(spot_type)
      return exit_status(plate)
    end

    'car not found'
  end

  def available_spots
    {
      small: @small,
      medium: @medium,
      large: @large
    }
  end

  def total_occupied
    @parking_spots.values.sum(&:size)
  end

  def total_available
    @small + @medium + @large
  end

  private

  def normalize_plate(license_plate_no)
    return nil if license_plate_no.nil?

    plate = license_plate_no.to_s.strip
    plate.empty? ? nil : plate
  end

  def normalize_size(car_size)
    return nil if car_size.nil?

    size = car_size.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  end

  def park_in_first_available(car, preferred_spots)
    preferred_spots.each do |spot_type|
      next unless available_count(spot_type.to_sym).positive?

      park_car(car, spot_type.to_sym)
      return parking_status(car, spot_type)
    end

    'No space available'
  end

  def park_large_car(car)
    if @large.positive?
      park_car(car, :large)
      return parking_status(car, 'large')
    end

    return parking_status(car, 'large') if shuffle_for_large_car(car)

    'No space available'
  end

  def shuffle_for_large_car(car)
    return false unless @large.zero?

    medium_in_large = @parking_spots[:large].find { |parked_car| parked_car[:size] == 'medium' }
    if medium_in_large && @medium.positive?
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium -= 1
      @large += 1

      park_car(car, :large)
      return true
    end

    small_in_large = @parking_spots[:large].find { |parked_car| parked_car[:size] == 'small' }
    if small_in_large
      if @small.positive?
        @parking_spots[:large].delete(small_in_large)
        @parking_spots[:small] << small_in_large
        @small -= 1
        @large += 1

        park_car(car, :large)
        return true
      elsif @medium.positive?
        @parking_spots[:large].delete(small_in_large)
        @parking_spots[:medium] << small_in_large
        @medium -= 1
        @large += 1

        park_car(car, :large)
        return true
      end
    end

    false
  end

  def park_car(car, spot_type)
    @parking_spots[spot_type] << car
    decrement_available(spot_type)
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

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : 'car not found'
  end
end

class ParkingTicket
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :id, :ticket_id, :entry_time, :license_plate, :license_plate_no, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id               = generate_ticket_id
    @ticket_id        = @id
    @license_plate    = normalize_plate(license_plate)
    @license_plate_no = @license_plate
    @car_size         = normalize_size(car_size)
    @entry_time       = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [((Time.now - @entry_time) / 3600.0), 0.0].max
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def normalize_plate(license_plate)
    license_plate.nil? ? '' : license_plate.to_s.strip
  end

  def normalize_size(car_size)
    size = car_size.nil? ? '' : car_size.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  end

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
  end
end

class ParkingFeeCalculator
  RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = normalize_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 if size.nil? || duration <= GRACE_PERIOD_HOURS

    billable_hours = duration.ceil
    total = billable_hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_size(car_size)
    return nil if car_size.nil?

    size = car_size.to_s.strip.downcase
    RATES.key?(size) ? size : nil
  end

  def normalize_duration(duration_hours)
    Float(duration_hours)
  rescue StandardError
    0.0
  else
    duration = Float(duration_hours)
    duration.negative? ? 0.0 : duration
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **kwargs)
    small  = kwargs.key?(:small_spots) ? kwargs[:small_spots] : small_spots
    medium = kwargs.key?(:medium_spots) ? kwargs[:medium_spots] : medium_spots
    large  = kwargs.key?(:large_spots) ? kwargs[:large_spots] : large_spots

    @garage          = ParkingGarage.new(small, medium, large)
    @fee_calculator  = ParkingFeeCalculator.new
    @active_tickets  = {}
    @tix_in_flight   = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size  = normalize_size(size)

    return failure_response('Invalid license plate') if normalized_plate.nil?
    return failure_response('Invalid car size') if normalized_size.nil?
    return failure_response('car already parked') if @active_tickets.key?(normalized_plate)

    message = @garage.admit_car(normalized_plate, normalized_size)

    if message.include?('is parked at')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message, ticket: nil }
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    return failure_response('Invalid license plate') if normalized_plate.nil?

    ticket = @active_tickets[normalized_plate]
    return failure_response('ticket not found') unless ticket

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
      total_occupied: @garage.total_occupied,
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
    return nil if plate.nil?

    normalized = plate.to_s.strip
    normalized.empty? ? nil : normalized
  end

  def normalize_size(size)
    return nil if size.nil?

    normalized = size.to_s.strip.downcase
    %w[small medium large].include?(normalized) ? normalized : nil
  end

  def failure_response(message)
    { success: false, message: message }
  end
end