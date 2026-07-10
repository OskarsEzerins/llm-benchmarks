require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

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
    plate = normalize_license_plate(license_plate_no)
    size = normalize_car_size(car_size)

    return parking_status unless plate && size

    car = { plate: plate, size: size }

    case size
    when 'small'
      park_small_car(car)
    when 'medium'
      park_medium_car(car)
    when 'large'
      park_large_car(car)
    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_license_plate(license_plate_no)
    return exit_status unless plate

    spot_key, car = find_car(plate)

    return exit_status unless car

    @parking_spots[spot_key].delete(car)
    increment_available_spot(spot_key)

    exit_status(plate)
  end

  def available_spots
    {
      small_available: @small,
      medium_available: @medium,
      large_available: @large,
      total_occupied: total_occupied,
      total_available: @small + @medium + @large
    }
  end

  def total_occupied
    @parking_spots.values.sum(&:size)
  end

  private

  def park_small_car(car)
    if @small.positive?
      park_in_spot(car, :small_spot, 'small')
    elsif @medium.positive?
      park_in_spot(car, :medium_spot, 'medium')
    elsif @large.positive?
      park_in_spot(car, :large_spot, 'large')
    else
      parking_status
    end
  end

  def park_medium_car(car)
    if @medium.positive?
      park_in_spot(car, :medium_spot, 'medium')
    elsif @large.positive?
      park_in_spot(car, :large_spot, 'large')
    elsif shuffle_for_medium
      park_in_spot(car, :medium_spot, 'medium')
    else
      parking_status
    end
  end

  def park_large_car(car)
    if @large.positive?
      park_in_spot(car, :large_spot, 'large')
    elsif shuffle_for_large
      park_in_spot(car, :large_spot, 'large')
    else
      parking_status
    end
  end

  def park_in_spot(car, spot_key, spot_type)
    @parking_spots[spot_key] << car
    decrement_available_spot(spot_key)
    parking_status(car, spot_type)
  end

  def shuffle_for_medium
    return false unless @small.positive?

    small_car_in_medium = @parking_spots[:medium_spot].find { |car| car[:size] == 'small' }
    return false unless small_car_in_medium

    @parking_spots[:medium_spot].delete(small_car_in_medium)
    @parking_spots[:small_spot] << small_car_in_medium

    @small -= 1
    @medium += 1

    true
  end

  def shuffle_for_large
    medium_car_in_large = @parking_spots[:large_spot].find { |car| car[:size] == 'medium' }
    if medium_car_in_large && @medium.positive?
      @parking_spots[:large_spot].delete(medium_car_in_large)
      @parking_spots[:medium_spot] << medium_car_in_large

      @medium -= 1
      @large += 1

      return true
    end

    small_car_in_large = @parking_spots[:large_spot].find { |car| car[:size] == 'small' }
    if small_car_in_large && @small.positive?
      @parking_spots[:large_spot].delete(small_car_in_large)
      @parking_spots[:small_spot] << small_car_in_large

      @small -= 1
      @large += 1

      return true
    end

    if small_car_in_large && @medium.positive?
      @parking_spots[:large_spot].delete(small_car_in_large)
      @parking_spots[:medium_spot] << small_car_in_large

      @medium -= 1
      @large += 1

      return true
    end

    false
  end

  def find_car(plate)
    @parking_spots.each do |spot_key, cars|
      car = cars.find { |parked_car| parked_car[:plate] == plate }
      return [spot_key, car] if car
    end

    [nil, nil]
  end

  def decrement_available_spot(spot_key)
    case spot_key
    when :small_spot
      @small -= 1
    when :medium_spot
      @medium -= 1
    when :large_spot
      @large -= 1
    end
  end

  def increment_available_spot(spot_key)
    case spot_key
    when :small_spot
      @small += 1
    when :medium_spot
      @medium += 1
    when :large_spot
      @large += 1
    end
  end

  def normalize_license_plate(license_plate_no)
    plate = license_plate_no.to_s.strip
    plate.empty? ? nil : plate
  end

  def normalize_car_size(car_size)
    size = car_size.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  end

  def parking_status(car = nil, spot_type = nil)
    if car && spot_type
      "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
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
end

class ParkingTicket
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :id, :ticket_id, :entry_time, :license_plate, :license_plate_no, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @ticket_id = @id
    @license_plate = normalize_license_plate(license_plate)
    @license_plate_no = @license_plate
    @car_size = normalize_car_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
  end

  def normalize_license_plate(license_plate)
    license_plate.to_s.strip
  end

  def normalize_car_size(car_size)
    size = car_size.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
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
    size = normalize_car_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 unless size
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    billable_hours = duration.ceil
    total = billable_hours * RATES[size]

    [total, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_car_size(car_size)
    size = car_size.to_s.strip.downcase
    RATES.key?(size) ? size : nil
  end

  def normalize_duration(duration_hours)
    duration = Float(duration_hours)
    duration.negative? ? 0.0 : duration
  rescue ArgumentError, TypeError
    0.0
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **kwargs)
    small = kwargs.key?(:small_spots) ? kwargs[:small_spots] : small_spots
    medium = kwargs.key?(:medium_spots) ? kwargs[:medium_spots] : medium_spots
    large = kwargs.key?(:large_spots) ? kwargs[:large_spots] : large_spots

    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_license_plate(plate)
    normalized_size = normalize_car_size(size)

    unless normalized_plate && normalized_size
      return {
        success: false,
        message: 'No space available',
        ticket: nil
      }
    end

    if @active_tickets.key?(normalized_plate)
      return {
        success: false,
        message: 'Car already parked',
        ticket: @active_tickets[normalized_plate]
      }
    end

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
      {
        success: false,
        message: message,
        ticket: nil
      }
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_license_plate(plate)

    unless normalized_plate && @active_tickets.key?(normalized_plate)
      return {
        success: false,
        message: 'Ticket not found',
        fee: 0.0,
        duration_hours: 0.0
      }
    end

    ticket = @active_tickets[normalized_plate]
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
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    normalized_plate = normalize_license_plate(plate)
    return nil unless normalized_plate

    @active_tickets[normalized_plate]
  end

  private

  def normalize_license_plate(plate)
    normalized = plate.to_s.strip
    normalized.empty? ? nil : normalized
  end

  def normalize_car_size(size)
    normalized = size.to_s.strip.downcase
    %w[small medium large].include?(normalized) ? normalized : nil
  end
end