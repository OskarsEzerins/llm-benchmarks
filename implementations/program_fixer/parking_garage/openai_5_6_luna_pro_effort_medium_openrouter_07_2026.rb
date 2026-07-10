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
    return 'No space available' if parked_plate?(plate)

    spot = case size
           when 'small'
             park_in(:small, plate, size) ||
               park_in(:medium, plate, size) ||
               park_in(:large, plate, size)
           when 'medium'
             park_in(:medium, plate, size) ||
               park_in(:large, plate, size)
           when 'large'
             park_large_car(plate, size)
           end

    spot ? parking_status({ plate: plate, size: size }, spot) : 'No space available'
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'No car found' if plate.nil?

    @parking_spots.each do |spot_type, cars|
      car = cars.find { |candidate| candidate[:plate] == plate }
      next unless car

      cars.delete(car)
      increment_available(spot_type)
      return exit_status(plate)
    end

    'No car found'
  end

  def shuffle_medium(car)
    plate = normalize_plate(car[:plate])
    size = normalize_size(car[:size])
    return 'No space available' unless plate && size == 'medium' && @small.positive?

    victim = @parking_spots[:medium].first || @parking_spots[:large].find do |candidate|
      candidate[:size] == 'medium'
    end
    return 'No space available' unless victim

    source = @parking_spots[:medium].include?(victim) ? :medium : :large
    @parking_spots[source].delete(victim)
    @parking_spots[:small] << victim
    @small -= 1
    @parking_spots[source] << { plate: plate, size: size }

    parking_status({ plate: plate, size: size }, source)
  end

  def shuffle_large(car)
    plate = normalize_plate(car[:plate])
    size = normalize_size(car[:size])
    return 'No space available' unless plate && size == 'large'
    return parking_status({ plate: plate, size: size }, :large) if @large.positive?

    return 'No space available' unless @medium.positive?

    victim = @parking_spots[:large].find { |candidate| candidate[:size] == 'medium' }
    return 'No space available' unless victim

    @parking_spots[:large].delete(victim)
    @parking_spots[:medium] << victim
    @medium -= 1
    @parking_spots[:large] << { plate: plate, size: size }

    parking_status({ plate: plate, size: size }, :large)
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    return 'No car found' if plate.nil?

    "car with license plate no. #{plate} exited"
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    value = plate.to_s
    value.strip.empty? ? nil : value
  end

  def normalize_size(size)
    return nil if size.nil?

    value = size.to_s.downcase
    VALID_SIZES.include?(value) ? value : nil
  end

  def parked_plate?(plate)
    @parking_spots.values.flatten.any? { |car| car[:plate] == plate }
  end

  def park_in(spot_type, plate, size)
    return nil unless available?(spot_type)

    @parking_spots[spot_type] << { plate: plate, size: size }
    decrement_available(spot_type)
    spot_type.to_s
  end

  def park_large_car(plate, size)
    return park_in(:large, plate, size) if @large.positive?

    return nil unless @medium.positive?

    victim = @parking_spots[:large].find { |car| car[:size] == 'medium' }
    return nil unless victim

    @parking_spots[:large].delete(victim)
    @parking_spots[:medium] << victim
    @medium -= 1
    @parking_spots[:large] << { plate: plate, size: size }
    'large'
  end

  def available?(spot_type)
    case spot_type
    when :small then @small.positive?
    when :medium then @medium.positive?
    when :large then @large.positive?
    else false
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
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
  end

  def normalize_size(size)
    value = size.to_s.downcase
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

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    duration = Float(duration_hours)
    return 0.0 unless RATES.key?(size)
    return 0.0 unless duration.finite? && duration.positive?
    return 0.0 if duration <= 0.25

    hours = duration.ceil
    [hours * RATES[size], MAX_FEE[size]].min.to_f
  rescue ArgumentError, TypeError
    0.0
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **options)
    small_spots = options[:small_spots] if options.key?(:small_spots)
    medium_spots = options[:medium_spots] if options.key?(:medium_spots)
    large_spots = options[:large_spots] if options.key?(:large_spots)

    @garage = ParkingGarage.new(small_spots || 0, medium_spots || 0, large_spots || 0)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    normalized_plate = plate.nil? ? nil : plate.to_s
    key = normalized_plate&.strip
    result = @garage.admit_car(plate, size)

    unless result == 'No space available'
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[key] = ticket
      return {
        success: true,
        message: result,
        ticket: ticket
      }
    end

    {
      success: false,
      message: 'No space available'
    }
  end

  def exit_car(plate)
    key = plate.nil? ? nil : plate.to_s.strip
    ticket = key.nil? ? nil : @tix_in_flight[key]

    return { success: false, message: 'No active ticket' } unless ticket
    return { success: false, message: 'Ticket expired' } unless ticket.valid?

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(ticket.license_plate)

    return { success: false, message: result } unless result.include?('exited')

    @tix_in_flight.delete(key)

    {
      success: true,
      message: result,
      fee: fee.to_f,
      duration_hours: duration
    }
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
    key = plate.nil? ? nil : plate.to_s.strip
    key.nil? ? nil : @tix_in_flight[key]
  end
end