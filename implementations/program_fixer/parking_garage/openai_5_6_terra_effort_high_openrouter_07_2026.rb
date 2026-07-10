require 'securerandom'

class ParkingGarage
  SPOT_TYPES = %w[small medium large].freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small = 0, medium = 0, large = 0)
    @small_capacity = normalize_capacity(small)
    @medium_capacity = normalize_capacity(medium)
    @large_capacity = normalize_capacity(large)

    @small_spots = []
    @medium_spots = []
    @large_spots = []

    @parking_spots = {
      small: @small_spots,
      medium: @medium_spots,
      large: @large_spots,
      small_spot: @small_spots,
      medium_spot: @medium_spots,
      large_spot: @large_spots
    }

    refresh_availability
  end

  def admit_car(license_plate_no, car_size)
    plate = self.class.normalize_plate(license_plate_no)
    size = self.class.normalize_size(car_size)

    return 'Invalid license plate or car size' unless plate && size
    return "car with license plate no. #{plate} is already parked" if parked?(plate)

    car = { plate: plate, license_plate_no: plate, size: size }

    spot_type = direct_spot_for(size)
    if spot_type
      spots_for(spot_type) << car
      refresh_availability
      return parking_status(car, spot_type)
    end

    shuffled_spot = repack_with(car)
    return parking_status(car, shuffled_spot) if shuffled_spot

    'No space available'
  end

  def exit_car(license_plate_no)
    plate = self.class.normalize_plate(license_plate_no)
    return 'No car found' unless plate

    spot_type = SPOT_TYPES.find do |type|
      spots_for(type).any? { |car| car[:plate] == plate }
    end

    return 'No car found' unless spot_type

    car = spots_for(spot_type).find { |vehicle| vehicle[:plate] == plate }
    spots_for(spot_type).delete(car)
    refresh_availability

    exit_status(plate)
  end

  def parked?(license_plate_no)
    plate = self.class.normalize_plate(license_plate_no)
    return false unless plate

    SPOT_TYPES.any? do |type|
      spots_for(type).any? { |car| car[:plate] == plate }
    end
  end

  def shuffle_medium(car)
    shuffle_car(car, 'medium')
  end

  def shuffle_large(car)
    shuffle_car(car, 'large')
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    return 'No car found' unless plate

    "car with license plate no. #{plate} exited"
  end

  def self.normalize_plate(plate)
    return nil if plate.nil?

    normalized = plate.to_s.strip
    normalized.empty? ? nil : normalized
  rescue StandardError
    nil
  end

  def self.normalize_size(size)
    return nil if size.nil?

    normalized = size.to_s.strip.downcase
    SPOT_TYPES.include?(normalized) ? normalized : nil
  rescue StandardError
    nil
  end

  private

  def normalize_capacity(value)
    capacity =
      if value.is_a?(Numeric)
        value.to_i
      elsif value.respond_to?(:to_i)
        value.to_i
      else
        0
      end

    [capacity, 0].max
  rescue StandardError
    0
  end

  def direct_spot_for(car_size)
    case car_size
    when 'small'
      return 'small' if @small.positive?
      return 'medium' if @medium.positive?
      return 'large' if @large.positive?
    when 'medium'
      return 'medium' if @medium.positive?
      return 'large' if @large.positive?
    when 'large'
      return 'large' if @large.positive?
    end

    nil
  end

  def shuffle_car(car, expected_size)
    plate = self.class.normalize_plate(car[:plate] || car[:license_plate_no])
    size = self.class.normalize_size(car[:size]) || expected_size

    return 'Invalid license plate or car size' unless plate && size
    return "car with license plate no. #{plate} is already parked" if parked?(plate)

    normalized_car = { plate: plate, license_plate_no: plate, size: size }
    spot_type = repack_with(normalized_car)

    spot_type ? parking_status(normalized_car, spot_type) : 'No space available'
  end

  def repack_with(new_car)
    cars = @small_spots.dup + @medium_spots.dup + @large_spots.dup + [new_car]

    new_small = []
    new_medium = []
    new_large = []

    cars.sort_by { |car| -size_rank(car[:size]) }.each do |car|
      target =
        case car[:size]
        when 'large'
          new_large.length < @large_capacity ? 'large' : nil
        when 'medium'
          if new_medium.length < @medium_capacity
            'medium'
          elsif new_large.length < @large_capacity
            'large'
          end
        when 'small'
          if new_small.length < @small_capacity
            'small'
          elsif new_medium.length < @medium_capacity
            'medium'
          elsif new_large.length < @large_capacity
            'large'
          end
        end

      return nil unless target

      case target
      when 'small' then new_small << car
      when 'medium' then new_medium << car
      when 'large' then new_large << car
      end
    end

    @small_spots.replace(new_small)
    @medium_spots.replace(new_medium)
    @large_spots.replace(new_large)
    refresh_availability

    SPOT_TYPES.find { |type| spots_for(type).include?(new_car) }
  end

  def size_rank(size)
    case size
    when 'large' then 3
    when 'medium' then 2
    else 1
    end
  end

  def spots_for(type)
    case type
    when 'small' then @small_spots
    when 'medium' then @medium_spots
    when 'large' then @large_spots
    end
  end

  def refresh_availability
    @small = @small_capacity - @small_spots.length
    @medium = @medium_capacity - @medium_spots.length
    @large = @large_capacity - @large_spots.length
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :license_plate_no, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = ParkingGarage.normalize_plate(license_plate).to_s
    @license_plate_no = @license_plate
    @car_size = ParkingGarage.normalize_size(car_size).to_s
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [((Time.now - @entry_time) / 3600.0), 0.0].max
  rescue StandardError
    0.0
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    SecureRandom.uuid
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
    size = ParkingGarage.normalize_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 unless size && duration
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    hours = duration.ceil
    fee = hours * RATES[size]

    [fee, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_duration(value)
    duration = Float(value)
    return nil unless duration.finite?
    return nil if duration.negative?

    duration
  rescue StandardError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage, :active_tickets

  def initialize(*args, small_spots: nil, medium_spots: nil, large_spots: nil)
    if args.length == 1 && args.first.is_a?(Hash)
      options = args.first
      small_spots = options[:small_spots] || options['small_spots']
      medium_spots = options[:medium_spots] || options['medium_spots']
      large_spots = options[:large_spots] || options['large_spots']
    elsif args.any?
      small_spots, medium_spots, large_spots = args
    end

    @garage = ParkingGarage.new(small_spots || 0, medium_spots || 0, large_spots || 0)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
    @tix_in_flight = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = ParkingGarage.normalize_plate(plate)
    normalized_size = ParkingGarage.normalize_size(size)

    unless normalized_plate && normalized_size
      return { success: false, message: 'Invalid license plate or car size' }
    end

    if @active_tickets.key?(normalized_plate)
      return {
        success: false,
        message: "car with license plate no. #{normalized_plate} is already parked"
      }
    end

    message = @garage.admit_car(normalized_plate, normalized_size)

    unless message.include?(' is parked at ')
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
    normalized_plate = ParkingGarage.normalize_plate(plate)
    ticket = normalized_plate && @active_tickets[normalized_plate]

    return { success: false, message: 'No active ticket found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    unless message.include?(' exited')
      return { success: false, message: message }
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
    total_available = @garage.small + @garage.medium + @garage.large

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_capacity - total_available,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    normalized_plate = ParkingGarage.normalize_plate(plate)
    normalized_plate ? @active_tickets[normalized_plate] : nil
  end

  private

  def total_capacity
    @garage.small + @garage.medium + @garage.large +
      @garage.parking_spots[:small].length +
      @garage.parking_spots[:medium].length +
      @garage.parking_spots[:large].length
  end
end