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

    return 'Invalid license plate' unless plate
    return 'Invalid car size' unless size
    return "car with license plate no. #{plate} is already parked" if parked?(plate)

    car = { plate: plate, size: size }

    case size
    when 'small'
      park_small_car(car)
    when 'medium'
      park_medium_car(car)
    when 'large'
      park_large_car(car)
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Car not found' unless plate

    @parking_spots.each do |spot_type, cars|
      car = cars.find { |vehicle| vehicle[:plate] == plate }
      next unless car

      cars.delete(car)
      increase_available_spot(spot_type)
      return "car with license plate no. #{plate} exited"
    end

    'Car not found'
  end

  def occupied_count
    @parking_spots.values.sum(&:size)
  end

  private

  def park_small_car(car)
    if @small.positive?
      add_car(car, :small)
      parking_message(car, 'small')
    elsif @medium.positive?
      add_car(car, :medium)
      parking_message(car, 'medium')
    elsif @large.positive?
      add_car(car, :large)
      parking_message(car, 'large')
    else
      'No space available'
    end
  end

  def park_medium_car(car)
    if @medium.positive?
      add_car(car, :medium)
      parking_message(car, 'medium')
    elsif @large.positive?
      add_car(car, :large)
      parking_message(car, 'large')
    else
      'No space available'
    end
  end

  def park_large_car(car)
    if @large.positive?
      add_car(car, :large)
      parking_message(car, 'large')
    elsif rearrange_for_large_car(car)
      parking_message(car, 'large')
    else
      'No space available'
    end
  end

  def rearrange_for_large_car(new_car)
    cars = @parking_spots.values.flatten + [new_car]

    capacities = {
      small: @small + @parking_spots[:small].size,
      medium: @medium + @parking_spots[:medium].size,
      large: @large + @parking_spots[:large].size
    }

    assignments = {
      small: [],
      medium: [],
      large: []
    }

    cars.sort_by { |car| size_priority(car[:size]) }.each do |car|
      destination = allowed_spots(car[:size]).find do |spot|
        assignments[spot].size < capacities[spot]
      end

      return false unless destination

      assignments[destination] << car
    end

    return false unless assignments[:large].include?(new_car)

    @parking_spots = assignments
    refresh_available_counts(capacities)
    true
  end

  def refresh_available_counts(capacities)
    @small = capacities[:small] - @parking_spots[:small].size
    @medium = capacities[:medium] - @parking_spots[:medium].size
    @large = capacities[:large] - @parking_spots[:large].size
  end

  def allowed_spots(size)
    case size
    when 'small' then %i[small medium large]
    when 'medium' then %i[medium large]
    when 'large' then %i[large]
    else []
    end
  end

  def size_priority(size)
    case size
    when 'large' then 0
    when 'medium' then 1
    else 2
    end
  end

  def add_car(car, spot_type)
    @parking_spots[spot_type] << car

    case spot_type
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
  end

  def increase_available_spot(spot_type)
    case spot_type
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end
  end

  def parked?(plate)
    @parking_spots.values.flatten.any? { |car| car[:plate] == plate }
  end

  def parking_message(car, spot_type)
    "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
  end

  def normalize_plate(plate)
    return nil if plate.nil?

    value = plate.to_s.strip
    value.empty? ? nil : value
  rescue StandardError
    nil
  end

  def normalize_size(size)
    return nil if size.nil?

    value = size.to_s.strip.downcase
    VALID_SIZES.include?(value) ? value : nil
  rescue StandardError
    nil
  end
end

class ParkingTicket
  attr_reader :id, :ticket_id, :license_plate, :license_plate_no, :car_size, :entry_time

  VALID_SIZES = %w[small medium large].freeze

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @ticket_id = @id
    @license_plate = normalize_plate(license_plate)
    @license_plate_no = @license_plate
    @car_size = normalize_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    duration_hours < 24.0
  end

  private

  def normalize_plate(plate)
    plate.nil? ? '' : plate.to_s.strip
  rescue StandardError
    ''
  end

  def normalize_size(size)
    value = size.to_s.strip.downcase
    VALID_SIZES.include?(value) ? value : nil
  rescue StandardError
    nil
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

    billed_hours = duration.ceil
    fee = billed_hours * RATES[size]

    [fee, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_size(size)
    value = size.to_s.strip.downcase
    RATES.key?(value) ? value : nil
  rescue StandardError
    nil
  end

  def normalize_duration(duration)
    value = Float(duration)
    return nil unless value.finite?
    return nil if value.negative?

    value
  rescue ArgumentError, TypeError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(*args, **kwargs)
    if args.length >= 3
      small_spots, medium_spots, large_spots = args[0, 3]
    elsif args.length == 1 && args.first.is_a?(Hash)
      options = args.first
      small_spots = options[:small_spots] || options['small_spots']
      medium_spots = options[:medium_spots] || options['medium_spots']
      large_spots = options[:large_spots] || options['large_spots']
    else
      small_spots = kwargs[:small_spots]
      medium_spots = kwargs[:medium_spots]
      large_spots = kwargs[:large_spots]
    end

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    result = @garage.admit_car(plate, size)

    unless result.start_with?('car with license plate no.') && result.include?(' is parked at ')
      return { success: false, message: result }
    end

    normalized_size = normalize_size(size)
    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @tix_in_flight[normalized_plate] = ticket

    {
      success: true,
      message: result,
      ticket: ticket
    }
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    ticket = @tix_in_flight[normalized_plate]

    unless ticket
      return {
        success: false,
        message: 'No active ticket found'
      }
    end

    result = @garage.exit_car(normalized_plate)

    unless result.include?(' exited')
      return {
        success: false,
        message: result
      }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    @tix_in_flight.delete(normalized_plate)

    {
      success: true,
      message: result,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.occupied_count,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tix_in_flight[normalize_plate(plate)]
  end

  private

  def normalize_plate(plate)
    return '' if plate.nil?

    plate.to_s.strip
  rescue StandardError
    ''
  end

  def normalize_size(size)
    value = size.to_s.strip.downcase
    %w[small medium large].include?(value) ? value : nil
  rescue StandardError
    nil
  end
end