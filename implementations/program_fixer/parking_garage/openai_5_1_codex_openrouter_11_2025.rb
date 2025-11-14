require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots

  def initialize(small, medium, large)
    small_capacity  = [small.to_i, 0].max
    medium_capacity = [medium.to_i, 0].max
    large_capacity  = [large.to_i, 0].max

    @capacity = {
      small: small_capacity,
      medium: medium_capacity,
      large: large_capacity
    }

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    return 'Invalid license plate' if plate.empty?

    size = normalize_size(car_size)
    return 'Invalid car size' unless size

    spot = determine_spot(size)
    return 'No space available' unless spot

    car = { plate: plate, car_size: size, spot_type: spot }
    @parking_spots[spot] << car
    success_message(plate, spot)
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Invalid license plate' if plate.empty?

    @parking_spots.each_value do |cars|
      car = cars.find { |c| c[:plate] == plate }
      next unless car

      cars.delete(car)
      return "car with license plate no. #{plate} exited"
    end
    'Car not found'
  end

  def available_spots(type)
    key = type.to_sym
    capacity = @capacity[key] || 0
    occupied = @parking_spots[key]&.size || 0
    remaining = capacity - occupied
    remaining.positive? ? remaining : 0
  end

  def total_occupied
    @parking_spots.values.map(&:size).reduce(0, :+)
  end

  def total_capacity
    @capacity.values.reduce(0, :+)
  end

  def total_available
    total_capacity - total_occupied
  end

  def small
    available_spots(:small)
  end

  def medium
    available_spots(:medium)
  end

  def large
    available_spots(:large)
  end

  private

  def determine_spot(size)
    order = case size
            when 'small' then [:small, :medium, :large]
            when 'medium' then [:medium, :large]
            when 'large'
              ensure_large_spot_available
              [:large]
            else
              []
            end
    order.find { |spot| available_spots(spot) > 0 }
  end

  def ensure_large_spot_available
    return true if available_spots(:large) > 0

    @parking_spots[:large].dup.each do |car|
      next if car[:car_size] == 'large'

      destinations = car[:car_size] == 'medium' ? [:medium] : [:small, :medium]
      destination = destinations.find { |spot| available_spots(spot) > 0 }
      next unless destination

      @parking_spots[:large].delete(car)
      car[:spot_type] = destination
      @parking_spots[destination] << car
      return true if available_spots(:large) > 0
    end
    false
  end

  def normalize_plate(value)
    value.to_s.strip
  end

  def normalize_size(value)
    size = value.to_s.strip.downcase
    %w[small medium large].include?(size) ? size : nil
  end

  def success_message(plate, spot)
    "car with license plate no. #{plate} is parked at #{spot}"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s.strip
    normalized_size = car_size.to_s.strip.downcase
    @car_size = %w[small medium large].include?(normalized_size) ? normalized_size : ''
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    elapsed = Time.now - @entry_time
    elapsed = 0 if elapsed.negative?
    elapsed / 3600.0
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = normalize_size(car_size)
    duration = normalize_duration(duration_hours)
    return 0.0 if size.nil? || duration.nil?
    return 0.0 if duration <= GRACE_PERIOD

    chargeable = duration - GRACE_PERIOD
    chargeable_hours = chargeable <= 0 ? 0 : chargeable.ceil
    fee = chargeable_hours * RATES[size]
    [fee, MAX_FEE[size]].min
  end

  private

  def normalize_size(value)
    size = value.to_s.strip.downcase
    RATES.key?(size) ? size : nil
  end

  def normalize_duration(value)
    return nil if value.nil?
    duration = value.to_f
    duration.negative? ? nil : duration
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    return failure('Invalid license plate') if normalized_plate.empty?

    normalized_size = normalize_size(size)
    return failure('Invalid car size') unless normalized_size

    message = @garage.admit_car(normalized_plate, normalized_size)
    if message.start_with?('car with license plate no.')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      failure(message)
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    return failure('Invalid license plate') if normalized_plate.empty?

    ticket = @active_tickets[normalized_plate]
    return failure('Ticket not found') unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    return failure(message) unless message.start_with?('car with license plate no.')

    @active_tickets.delete(normalized_plate)
    { success: true, message: message, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available: @garage.available_spots(:small),
      medium_available: @garage.available_spots(:medium),
      large_available: @garage.available_spots(:large),
      total_occupied: @garage.total_occupied,
      total_available: @garage.total_available,
      active_tickets: @active_tickets.size
    }
  end

  def find_ticket(plate)
    @active_tickets[normalize_plate(plate)]
  end

  private

  def normalize_plate(value)
    value.to_s.strip
  end

  def normalize_size(value)
    size = value.to_s.strip.downcase
    %w[small medium large].include?(size) ? size : nil
  end

  def failure(message)
    { success: false, message: message }
  end
end