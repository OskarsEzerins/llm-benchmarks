require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = normalize_count(small)
    @medium = normalize_count(medium)
    @large = normalize_count(large)

    @capacity = {
      small: @small,
      medium: @medium,
      large: @large
    }

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)

    return no_space_message unless plate && size

    spot = find_available_spot(size)

    unless spot
      allowed_spots(size).each do |candidate_spot|
        next if available_count(candidate_spot).positive?

        if free_spot(candidate_spot)
          spot = candidate_spot
          break
        end
      end
    end

    return no_space_message unless spot

    car = {
      plate: plate,
      license_plate_no: plate,
      size: size,
      car_size: size
    }

    @parking_spots[spot] << car
    decrement_available(spot)

    parking_status(car, spot.to_s)
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Car not found' unless plate

    @parking_spots.each do |spot, cars|
      car = cars.find { |parked_car| parked_car[:plate] == plate }

      next unless car

      cars.delete(car)
      increment_available(spot)
      return exit_status(plate)
    end

    'Car not found'
  end

  def total_available
    @small + @medium + @large
  end

  def total_occupied
    @parking_spots.values.sum(&:size)
  end

  def available_spots
    {
      small: @small,
      medium: @medium,
      large: @large
    }
  end

  private

  def normalize_count(value)
    [value.to_i, 0].max
  rescue StandardError
    0
  end

  def normalize_plate(plate)
    normalized = plate.to_s.strip
    normalized.empty? ? nil : normalized
  end

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    VALID_SIZES.include?(normalized) ? normalized : nil
  end

  def allowed_spots(size)
    case size
    when 'small'
      %i[small medium large]
    when 'medium'
      %i[medium large]
    when 'large'
      %i[large]
    else
      []
    end
  end

  def find_available_spot(size)
    allowed_spots(size).find { |spot| available_count(spot).positive? }
  end

  def available_count(spot)
    case spot
    when :small then @small
    when :medium then @medium
    when :large then @large
    else 0
    end
  end

  def increment_available(spot)
    case spot
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end
  end

  def decrement_available(spot)
    case spot
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
  end

  def preferred_destinations_for(size, current_spot)
    spots = allowed_spots(size)
    current_index = spots.index(current_spot)

    return [] unless current_index

    spots[0...current_index]
  end

  def free_spot(spot, visited = [])
    return true if available_count(spot).positive?
    return false if visited.include?(spot)

    @parking_spots[spot].dup.each do |car|
      preferred_destinations_for(car[:size], spot).each do |destination|
        next if visited.include?(destination)

        if available_count(destination).positive? || free_spot(destination, visited + [spot])
          next unless available_count(destination).positive?

          move_car(car, spot, destination)
          return true
        end
      end
    end

    false
  end

  def move_car(car, from_spot, to_spot)
    @parking_spots[from_spot].delete(car)
    increment_available(from_spot)

    @parking_spots[to_spot] << car
    decrement_available(to_spot)
  end

  def parking_status(car = nil, space = nil)
    return no_space_message unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    return 'Car not found' unless plate

    "car with license plate no. #{plate} exited"
  end

  def no_space_message
    'No space available'
  end
end

class ParkingTicket
  VALID_SIZES = %w[small medium large].freeze
  EXPIRATION_HOURS = 24.0

  attr_reader :id, :ticket_id, :entry_time, :license_plate, :license_plate_no, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @ticket_id = @id
    @license_plate = license_plate.to_s.strip
    @license_plate_no = @license_plate
    @car_size = normalize_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    duration = (Time.now - @entry_time) / 3600.0
    duration.negative? ? 0.0 : duration
  end

  def valid?
    duration_hours <= EXPIRATION_HOURS
  end

  private

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    VALID_SIZES.include?(normalized) ? normalized : ''
  end

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

  DAILY_MAXIMUMS = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  MAX_FEE = DAILY_MAXIMUMS
  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = normalize_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 unless size
    return 0.0 unless duration
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    billable_hours = duration.ceil
    total = billable_hours * RATES[size]

    [total, DAILY_MAXIMUMS[size]].min.to_f
  end

  private

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    RATES.key?(normalized) ? normalized : nil
  end

  def normalize_duration(duration)
    normalized = Float(duration)
    return nil unless normalized.finite?
    return nil if normalized.negative?

    normalized
  rescue StandardError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(*args, **kwargs)
    small_spots = kwargs.key?(:small_spots) ? kwargs[:small_spots] : kwargs.fetch(:small, args[0])
    medium_spots = kwargs.key?(:medium_spots) ? kwargs[:medium_spots] : kwargs.fetch(:medium, args[1])
    large_spots = kwargs.key?(:large_spots) ? kwargs[:large_spots] : kwargs.fetch(:large, args[2])

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
    @tix_in_flight = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    return { success: false, message: 'No space available' } unless normalized_plate && normalized_size
    return { success: false, message: 'Car already parked' } if @active_tickets.key?(normalized_plate)

    message = @garage.admit_car(normalized_plate, normalized_size)

    if message.include?('parked')
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
        message: message
      }
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    ticket = normalized_plate ? @active_tickets[normalized_plate] : nil

    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    return { success: false, message: message } unless message.include?('exited')

    @active_tickets.delete(normalized_plate)

    {
      success: true,
      message: message,
      fee: fee,
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
end