require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = normalize_capacity(small)
    @medium = normalize_capacity(medium)
    @large = normalize_capacity(large)

    @initial_capacity = {
      small: @small,
      medium: @medium,
      large: @large
    }

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

    car = {
      plate: plate,
      license_plate_no: plate,
      size: size,
      car_size: size
    }

    spot_type =
      case size
      when 'small'
        first_available_spot(:small, :medium, :large)
      when 'medium'
        first_available_spot(:medium, :large) || shuffle_medium
      when 'large'
        available?(:large) ? :large : shuffle_large
      end

    return 'No space available' unless spot_type

    park_in_spot(car, spot_type)
    parking_status(car, spot_type.to_s)
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Car not found' unless plate

    spot_type, car = find_parked_car(plate)
    return 'Car not found' unless car

    @parking_spots[spot_key(spot_type)].delete(car)
    change_availability(spot_type, 1)

    exit_status(plate)
  end

  def shuffle_medium(_car = nil)
    return :medium if available?(:medium)
    return :large if available?(:large)

    # Move a small car from a medium spot back into an available small spot.
    if available?(:small)
      small_car = @parking_spots[:medium_spot].find { |car| car[:size] == 'small' }
      if small_car
        move_car(small_car, :medium, :small)
        return :medium
      end
    end

    nil
  end

  def shuffle_large(_car = nil)
    return :large if available?(:large)

    destination = relocate_large_spot_occupant
    return :large if destination

    # Free a medium spot by moving a small car into a small spot, then move
    # a medium/small car out of a large spot.
    if available?(:small)
      small_car = @parking_spots[:medium_spot].find { |car| car[:size] == 'small' }
      move_car(small_car, :medium, :small) if small_car
    end

    relocate_large_spot_occupant ? :large : nil
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    return 'Car not found' unless plate

    "car with license plate no. #{plate} exited"
  end

  def total_available
    @small + @medium + @large
  end

  def total_occupied
    total_capacity - total_available
  end

  def total_capacity
    @initial_capacity.values.sum
  end

  private

  def normalize_capacity(value)
    capacity = Integer(value)
    capacity.negative? ? 0 : capacity
  rescue ArgumentError, TypeError
    0
  end

  def normalize_plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  end

  def normalize_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  end

  def first_available_spot(*spot_types)
    spot_types.find { |spot_type| available?(spot_type) }
  end

  def available?(spot_type)
    availability(spot_type).positive?
  end

  def availability(spot_type)
    instance_variable_get("@#{spot_type}")
  end

  def change_availability(spot_type, amount)
    current = availability(spot_type)
    instance_variable_set("@#{spot_type}", current + amount)
  end

  def spot_key(spot_type)
    :"#{spot_type}_spot"
  end

  def park_in_spot(car, spot_type)
    @parking_spots[spot_key(spot_type)] << car
    change_availability(spot_type, -1)
  end

  def move_car(car, from_type, to_type)
    return false unless car && available?(to_type)

    source = @parking_spots[spot_key(from_type)]
    return false unless source.delete(car)

    change_availability(from_type, 1)
    park_in_spot(car, to_type)
    true
  end

  def relocate_large_spot_occupant
    @parking_spots[:large_spot].each do |car|
      destinations =
        case car[:size]
        when 'small'
          %i[small medium]
        when 'medium'
          [:medium]
        else
          []
        end

      destination = destinations.find { |type| available?(type) }
      next unless destination

      return destination if move_car(car, :large, destination)
    end

    nil
  end

  def find_parked_car(plate)
    %i[small medium large].each do |spot_type|
      car = @parking_spots[spot_key(spot_type)].find do |parked_car|
        parked_car[:plate].to_s == plate
      end
      return [spot_type, car] if car
    end

    [nil, nil]
  end
end

class ParkingTicket
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :id, :entry_time, :license_plate, :license_plate_no, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.nil? ? '' : license_plate.to_s.strip
    @license_plate_no = @license_plate
    @car_size = normalize_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    duration = (Time.now - @entry_time) / 3600.0
    duration.negative? ? 0.0 : duration.to_f
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def normalize_size(value)
    size = value.nil? ? '' : value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : ''
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

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = normalize_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 unless size && duration
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    billable_hours = duration.ceil
    fee = billable_hours * RATES[size]

    [fee.to_f, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    RATES.key?(size) ? size : nil
  end

  def normalize_duration(value)
    duration = Float(value)
    return nil unless duration.finite?
    return nil if duration.negative?

    duration
  rescue ArgumentError, TypeError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(*args, small_spots: nil, medium_spots: nil, large_spots: nil, **_options)
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

    unless normalized_plate && normalized_size
      return { success: false, message: 'No space available' }
    end

    if @active_tickets.key?(normalized_plate)
      return { success: false, message: 'Car is already parked' }
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

    unless ticket
      return {
        success: false,
        message: 'No active ticket found'
      }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    unless message == "car with license plate no. #{normalized_plate} exited"
      return {
        success: false,
        message: message
      }
    end

    @active_tickets.delete(normalized_plate)

    {
      success: true,
      message: message,
      fee: fee.to_f,
      duration_hours: duration.to_f
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
    normalized_plate ? @active_tickets[normalized_plate] : nil
  end

  private

  def normalize_plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  end

  def normalize_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    %w[small medium large].include?(size) ? size : nil
  end
end