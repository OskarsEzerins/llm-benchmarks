require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @capacity = {
      small: normalize_count(small),
      medium: normalize_count(medium),
      large: normalize_count(large)
    }
    @small = @capacity[:small]
    @medium = @capacity[:medium]
    @large = @capacity[:large]
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)

    return 'Invalid license plate' if plate.nil?
    return 'Invalid car size' unless VALID_SIZES.include?(size)
    return "Vehicle with license plate no. #{plate} is already in the garage" if plate_parked?(plate)

    car = { plate: plate, size: size }

    case size
    when 'small'
      return park_car(car, :small) if @small > 0
      return park_car(car, :medium) if @medium > 0
      return park_car(car, :large) if @large > 0
      parking_status
    when 'medium'
      return park_car(car, :medium) if @medium > 0
      return park_car(car, :large) if @large > 0
      shuffle_medium(car)
    when 'large'
      return park_car(car, :large) if @large > 0
      shuffle_large(car)
    else
      'Invalid car size'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Invalid license plate' if plate.nil?

    %i[small medium large].each do |spot_type|
      cars = @parking_spots[spot_type]
      index = cars.index { |c| c[:plate] == plate }
      next if index.nil?

      cars.delete_at(index)
      adjust_available(spot_type, 1)
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    return parking_status unless car.is_a?(Hash)

    if @small > 0
      small_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if small_in_medium && move_car(small_in_medium, :medium, :small)
        return park_car(car, :medium)
      end

      small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_in_large && move_car(small_in_large, :large, :small)
        return park_car(car, :large)
      end
    end

    parking_status
  end

  def shuffle_large(car)
    return parking_status unless car.is_a?(Hash)

    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium > 0 && move_car(medium_in_large, :large, :medium)
      return park_car(car, :large)
    end

    small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if small_in_large && @small > 0 && move_car(small_in_large, :large, :small)
      return park_car(car, :large)
    end

    small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if small_in_large && @medium > 0 && move_car(small_in_large, :large, :medium)
      return park_car(car, :large)
    end

    if @small > 0
      medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      small_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if medium_in_large && small_in_medium &&
         move_car(small_in_medium, :medium, :small) &&
         move_car(medium_in_large, :large, :medium)
        return park_car(car, :large)
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
      'No car found'
    end
  end

  private

  def normalize_count(value)
    return 0 if value.nil?

    count = value.to_i
    count.negative? ? 0 : count
  rescue StandardError
    0
  end

  def normalize_plate(plate)
    return nil if plate.nil?

    text = plate.to_s.strip
    text.empty? ? nil : text
  rescue StandardError
    nil
  end

  def normalize_size(size)
    return nil if size.nil?

    size.to_s.downcase.strip
  rescue StandardError
    nil
  end

  def plate_parked?(plate)
    @parking_spots.each_value.any? { |cars| cars.any? { |car| car[:plate] == plate } }
  end

  def park_car(car, spot_type)
    return parking_status unless available_count(spot_type) > 0

    @parking_spots[spot_type] << car
    adjust_available(spot_type, -1)
    parking_status(car, spot_type.to_s)
  end

  def move_car(car, from_spot, to_spot)
    return false if car.nil?
    return false unless available_count(to_spot) > 0

    index = @parking_spots[from_spot].index { |parked| parked.equal?(car) }
    return false if index.nil?

    @parking_spots[from_spot].delete_at(index)
    @parking_spots[to_spot] << car
    adjust_available(from_spot, 1)
    adjust_available(to_spot, -1)
    true
  end

  def available_count(spot_type)
    case spot_type
    when :small then @small
    when :medium then @medium
    when :large then @large
    else 0
    end
  end

  def adjust_available(spot_type, delta)
    updated = available_count(spot_type) + delta
    updated = 0 if updated.negative?
    cap = @capacity[spot_type] || 0
    updated = cap if updated > cap

    case spot_type
    when :small then @small = updated
    when :medium then @medium = updated
    when :large then @large = updated
    end
  end
end

class ParkingTicket
  attr_reader :id, :car_size, :license_plate
  attr_accessor :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.nil? ? '' : license_plate.to_s.strip
    @car_size = car_size.to_s.downcase.strip
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def license_plate_no
    @license_plate
  end

  def duration_hours
    return 0.0 if @entry_time.nil?

    ((Time.now - @entry_time) / 3600.0).to_f
  rescue StandardError
    0.0
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TKT-#{SecureRandom.uuid}"
  end
end

class ParkingFeeCalculator
  GRACE_PERIOD_HOURS = 0.25

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

  def calculate_fee(car_size = nil, duration_hours = nil)
    size = car_size.to_s.downcase.strip
    duration = parse_duration(duration_hours)
    return 0.0 if duration.nil? || duration <= GRACE_PERIOD_HOURS
    return 0.0 unless RATES.key?(size)

    billable_hours = (duration - GRACE_PERIOD_HOURS).ceil
    return 0.0 if billable_hours <= 0

    fee = billable_hours * RATES[size]
    [fee, MAX_FEE[size]].min.to_f
  rescue StandardError
    0.0
  end

  private

  def parse_duration(value)
    return nil if value.nil?

    number = value.is_a?(Numeric) ? value.to_f : Float(value)
    return nil if number.nan? || number.infinite?

    number
  rescue ArgumentError, TypeError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    message = @garage.admit_car(plate, size).to_s
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    if message.include?('is parked at') && normalized_plate
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  rescue StandardError
    { success: false, message: 'No space available' }
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    return { success: false, message: 'Invalid license plate' } if normalized_plate.nil?

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'No ticket found' } unless ticket

    duration = ticket.duration_hours.to_f
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration).to_f
    message = @garage.exit_car(normalized_plate).to_s

    if message.include?('exited')
      @active_tickets.delete(normalized_plate)
      {
        success: true,
        message: message,
        fee: fee,
        duration_hours: duration
      }
    else
      { success: false, message: message }
    end
  rescue StandardError
    { success: false, message: 'No car found' }
  end

  def garage_status
    spots = @garage.parking_spots
    small_available = @garage.small.to_i
    medium_available = @garage.medium.to_i
    large_available = @garage.large.to_i
    total_available = small_available + medium_available + large_available
    total_occupied = spots[:small].length + spots[:medium].length + spots[:large].length

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
    return nil if plate.nil?

    text = plate.to_s.strip
    text.empty? ? nil : text
  rescue StandardError
    nil
  end

  def normalize_size(size)
    return nil if size.nil?

    size.to_s.downcase.strip
  rescue StandardError
    nil
  end
end