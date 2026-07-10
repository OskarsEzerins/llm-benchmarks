require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = normalize_capacity(small)
    @medium = normalize_capacity(medium)
    @large = normalize_capacity(large)

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)

    return 'No space available' unless plate && size

    car = { plate: plate, size: size }

    spot_type =
      case size
      when 'small'
        allocate_to_first_available(car, %w[small medium large])
      when 'medium'
        allocate_to_first_available(car, %w[medium large]) ||
          shuffle_for_medium(car)
      when 'large'
        allocate_to_first_available(car, ['large']) ||
          shuffle_for_large(car)
      end

    spot_type ? parking_status(car, spot_type) : parking_status
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status unless plate

    %w[small medium large].each do |spot_type|
      collection = @parking_spots[spot_key(spot_type)]
      car = collection.find { |parked_car| parked_car[:plate] == plate }

      next unless car

      collection.delete(car)
      increment_available(spot_type)
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    if available?('small')
      small_car = @parking_spots[:medium_spot].find do |parked_car|
        parked_car[:size] == 'small'
      end

      if small_car
        move_car(small_car, 'medium', 'small')
        return allocate_to_first_available(car, ['medium'])
      end

      small_car = @parking_spots[:large_spot].find do |parked_car|
        parked_car[:size] == 'small'
      end

      if small_car
        move_car(small_car, 'large', 'small')
        return allocate_to_first_available(car, ['large'])
      end
    end

    if available?('medium')
      small_car = @parking_spots[:large_spot].find do |parked_car|
        parked_car[:size] == 'small'
      end

      if small_car
        move_car(small_car, 'large', 'medium')
        return allocate_to_first_available(car, ['large'])
      end
    end

    nil
  end

  def shuffle_large(car)
    relocations = [
      ['medium', %w[medium]],
      ['small', %w[small medium]]
    ]

    relocations.each do |car_size, destinations|
      victim = @parking_spots[:large_spot].find do |parked_car|
        parked_car[:size] == car_size
      end
      next unless victim

      destination = destinations.find { |spot_type| available?(spot_type) }
      next unless destination

      move_car(victim, 'large', destination)
      return allocate_to_first_available(car, ['large'])
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
    if plate
      "car with license plate no. #{plate} exited"
    else
      'Car not found'
    end
  end

  private

  def normalize_capacity(value)
    capacity = Integer(value)
    [capacity, 0].max
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

  def allocate_to_first_available(car, spot_types)
    spot_type = spot_types.find { |type| available?(type) }
    return nil unless spot_type

    @parking_spots[spot_key(spot_type)] << car
    decrement_available(spot_type)
    spot_type
  end

  def move_car(car, source_type, destination_type)
    @parking_spots[spot_key(source_type)].delete(car)
    increment_available(source_type)

    @parking_spots[spot_key(destination_type)] << car
    decrement_available(destination_type)
  end

  def available?(spot_type)
    public_send(spot_type).positive?
  end

  def spot_key(spot_type)
    "#{spot_type}_spot".to_sym
  end

  def decrement_available(spot_type)
    instance_variable_set(
      "@#{spot_type}",
      instance_variable_get("@#{spot_type}") - 1
    )
  end

  def increment_available(spot_type)
    instance_variable_set(
      "@#{spot_type}",
      instance_variable_get("@#{spot_type}") + 1
    )
  end
end

class ParkingTicket
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :id, :entry_time, :car_size, :license_plate
  alias license_plate_no license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size = normalize_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    duration = (Time.now - @entry_time) / 3600.0
    [duration, 0.0].max
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def normalize_size(value)
    size = value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
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

    total = duration.ceil * RATES[size]
    [total, MAX_FEE[size]].min.to_f
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

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **options)
    small_spots = options[:small_spots] if options.key?(:small_spots)
    medium_spots = options[:medium_spots] if options.key?(:medium_spots)
    large_spots = options[:large_spots] if options.key?(:large_spots)

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
      return { success: false, message: 'Car not found' }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    unless message.include?('exited')
      return { success: false, message: message }
    end

    @active_tickets.delete(normalized_plate)

    {
      success: true,
      message: message,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @active_tickets.size,
      total_available: total_available
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