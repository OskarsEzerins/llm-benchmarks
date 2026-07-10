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
    return 'No space available' unless plate && size

    car = { plate: plate, size: size }

    spot_type =
      case size
      when 'small'
        if @small > 0
          :small
        elsif @medium > 0
          :medium
        elsif @large > 0
          :large
        end
      when 'medium'
        if @medium > 0
          :medium
        elsif @large > 0
          :large
        end
      when 'large'
        if @large > 0
          :large
        elsif shuffle_for_large
          :large
        end
      end

    return 'No space available' unless spot_type

    @parking_spots[spot_type] << car
    decrement_capacity(spot_type)
    parking_status(car, spot_type.to_s)
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'No car found' unless plate

    @parking_spots.each do |spot_type, cars|
      car = cars.find { |item| item[:plate] == plate }
      next unless car

      cars.delete(car)
      increment_capacity(spot_type)
      return exit_status(plate)
    end

    'No car found'
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    return 'No car found' unless plate

    "car with license plate no. #{plate} exited"
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    value = plate.to_s
    value.strip.empty? ? nil : value
  end

  def normalize_size(size)
    value = size.to_s.downcase
    VALID_SIZES.include?(value) ? value : nil
  end

  def decrement_capacity(spot_type)
    case spot_type
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
  end

  def increment_capacity(spot_type)
    case spot_type
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end
  end

  def shuffle_for_large
    return false unless @medium > 0

    victim = @parking_spots[:large].find { |car| car[:size] == 'medium' }
    return false unless victim

    @parking_spots[:large].delete(victim)
    @parking_spots[:medium] << victim
    @large += 1
    @medium -= 1
    true
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
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
    return 0.0 if duration.nan? || duration <= 0.25
    return 0.0 if duration.infinite?

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
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)
    result = @garage.admit_car(normalized_plate, normalized_size)

    if result != 'No space available' && normalized_plate
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @tix_in_flight[normalized_plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: 'No space available' }
    end
  end

  def exit_car(plate)
    key = normalize_plate(plate)
    ticket = key && @tix_in_flight[key]
    return { success: false, message: 'No active ticket found' } unless ticket

    duration = ticket.duration_hours
    result = @garage.exit_car(key)
    return { success: false, message: result } if result == 'No car found'

    @tix_in_flight.delete(key)

    {
      success: true,
      message: result,
      fee: @fee_calculator.calculate_fee(ticket.car_size, duration),
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
    key = normalize_plate(plate)
    key && @tix_in_flight[key]
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    value = plate.to_s
    value.strip.empty? ? nil : value
  end

  def normalize_size(size)
    value = size.to_s.downcase
    ParkingGarage::VALID_SIZES.include?(value) ? value : nil
  end
end