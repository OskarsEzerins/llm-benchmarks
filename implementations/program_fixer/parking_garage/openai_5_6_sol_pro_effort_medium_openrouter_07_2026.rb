require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze
  SPOT_KEYS = {
    'small' => :small_spot,
    'medium' => :medium_spot,
    'large' => :large_spot
  }.freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @capacities = {
      small: normalize_capacity(small),
      medium: normalize_capacity(medium),
      large: normalize_capacity(large)
    }

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }

    update_availability
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)

    return parking_status if plate.nil? || size.nil?

    car = { plate: plate, size: size }

    preferred_spots(size).each do |spot_type|
      next unless available_for?(spot_type)

      park_in_spot(car, spot_type)
      return parking_status(car, spot_type)
    end

    case size
    when 'medium'
      shuffle_medium(car)
    when 'large'
      shuffle_large(car)
    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status if plate.nil?

    @parking_spots.each do |_spot_key, cars|
      car = cars.find { |parked_car| parked_car[:plate] == plate }
      next unless car

      cars.delete(car)
      update_availability
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    normalized_car = normalize_car(car, 'medium')
    return parking_status unless normalized_car

    repack_with(normalized_car)
  end

  def shuffle_large(car)
    normalized_car = normalize_car(car, 'large')
    return parking_status unless normalized_car

    repack_with(normalized_car)
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

  def total_occupied
    @parking_spots.values.sum(&:length)
  end

  def total_available
    @small + @medium + @large
  end

  private

  def normalize_capacity(value)
    capacity = Integer(value)
    [capacity, 0].max
  rescue ArgumentError, TypeError
    0
  end

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

  def normalize_car(car, expected_size)
    return nil unless car.is_a?(Hash)

    plate = normalize_plate(car[:plate])
    size = normalize_size(car[:size] || expected_size)
    return nil unless plate && size == expected_size

    { plate: plate, size: size }
  end

  def preferred_spots(size)
    case size
    when 'small'
      %w[small medium large]
    when 'medium'
      %w[medium large]
    when 'large'
      %w[large]
    else
      []
    end
  end

  def available_for?(spot_type)
    key = SPOT_KEYS.fetch(spot_type)
    @parking_spots[key].length < @capacities.fetch(spot_type.to_sym)
  end

  def park_in_spot(car, spot_type)
    @parking_spots[SPOT_KEYS.fetch(spot_type)] << car
    update_availability
  end

  def repack_with(incoming_car)
    all_cars = @parking_spots.values.flatten + [incoming_car]

    new_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }

    large_cars = all_cars.select { |car| car[:size] == 'large' }
    medium_cars = all_cars.select { |car| car[:size] == 'medium' }
    small_cars = all_cars.select { |car| car[:size] == 'small' }

    return parking_status if large_cars.length > @capacities[:large]

    large_cars.each { |car| new_spots[:large_spot] << car }

    medium_cars.each do |car|
      if new_spots[:medium_spot].length < @capacities[:medium]
        new_spots[:medium_spot] << car
      elsif new_spots[:large_spot].length < @capacities[:large]
        new_spots[:large_spot] << car
      else
        return parking_status
      end
    end

    small_cars.each do |car|
      if new_spots[:small_spot].length < @capacities[:small]
        new_spots[:small_spot] << car
      elsif new_spots[:medium_spot].length < @capacities[:medium]
        new_spots[:medium_spot] << car
      elsif new_spots[:large_spot].length < @capacities[:large]
        new_spots[:large_spot] << car
      else
        return parking_status
      end
    end

    incoming_spot = new_spots.find do |_spot_key, cars|
      cars.any? { |car| car.equal?(incoming_car) }
    end

    return parking_status unless incoming_spot

    @parking_spots = new_spots
    update_availability

    spot_type = incoming_spot.first.to_s.sub('_spot', '')
    parking_status(incoming_car, spot_type)
  end

  def update_availability
    @small = @capacities[:small] - @parking_spots[:small_spot].length
    @medium = @capacities[:medium] - @parking_spots[:medium_spot].length
    @large = @capacities[:large] - @parking_spots[:large_spot].length
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate, :license_plate_no

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = normalize_plate(license_plate)
    @license_plate_no = @license_plate
    @car_size = normalize_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    duration = (Time.now - @entry_time) / 3600.0
    [duration, 0.0].max
  end

  def valid?
    duration_hours < 24.0
  end

  private

  def normalize_plate(license_plate)
    license_plate.nil? ? '' : license_plate.to_s.strip
  end

  def normalize_size(car_size)
    car_size.nil? ? '' : car_size.to_s.strip.downcase
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
    return 0.0 if duration.negative? || duration <= GRACE_PERIOD_HOURS

    billable_hours = duration.ceil
    total = billable_hours * RATES.fetch(size)

    [total, MAX_FEE.fetch(size)].min.to_f
  end

  private

  def normalize_size(car_size)
    return nil if car_size.nil?

    size = car_size.to_s.strip.downcase
    RATES.key?(size) ? size : nil
  end

  def normalize_duration(duration_hours)
    duration = Float(duration_hours)
    duration.finite? ? duration : nil
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
    @tix_in_flight = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    unless normalized_plate && normalized_size
      return { success: false, message: 'No space available' }
    end

    if @active_tickets.key?(normalized_plate)
      return {
        success: false,
        message: "car with license plate no. #{normalized_plate} is already parked"
      }
    end

    result = @garage.admit_car(normalized_plate, normalized_size)

    unless result.include?('is parked at')
      return { success: false, message: result }
    end

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @active_tickets[normalized_plate] = ticket

    {
      success: true,
      message: result,
      ticket: ticket
    }
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    ticket = normalized_plate && @active_tickets[normalized_plate]

    unless ticket
      return {
        success: false,
        message: 'Car not found'
      }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(normalized_plate)

    unless result.include?('exited')
      return {
        success: false,
        message: result
      }
    end

    @active_tickets.delete(normalized_plate)

    {
      success: true,
      message: result,
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
end