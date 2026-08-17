require 'securerandom'

module ParkingNormalization
  VALID_CAR_SIZES = %w[small medium large].freeze

  def normalize_plate(plate)
    plate.to_s.strip
  end

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    VALID_CAR_SIZES.include?(normalized) ? normalized : nil
  end
end

class ParkingGarage
  include ParkingNormalization

  attr_reader :parking_spots, :small, :medium, :large,
              :total_small, :total_medium, :total_large

  def initialize(small, medium, large)
    @small  = non_negative_int(small)
    @medium = non_negative_int(medium)
    @large  = non_negative_int(large)

    @total_small  = @small
    @total_medium = @medium
    @total_large  = @large

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

    return "car with license plate no. #{plate} is already parked" if car_present?(plate)

    spot = find_spot_for(size)

    unless spot
      return 'No space available' unless try_shuffle_for(size)

      spot = find_spot_for(size)
      return 'No space available' unless spot
    end

    park_in(spot, plate, size)
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Invalid license plate' if plate.empty?

    [:small, :medium, :large].each do |spot_type|
      car = @parking_spots[spot_type].detect { |c| c[:plate] == plate }

      next unless car

      @parking_spots[spot_type].delete(car)
      increment_spot(spot_type)

      return "car with license plate no. #{plate} exited"
    end

    "car with license plate no. #{plate} not found"
  end

  def total_spots
    @total_small + @total_medium + @total_large
  end

  def total_available
    @small + @medium + @large
  end

  def total_occupied
    @parking_spots.values.inject(0) { |sum, cars| sum + cars.size }
  end

  private

  def non_negative_int(value)
    int = value.respond_to?(:to_i) ? value.to_i : value.to_s.to_i
    int.negative? ? 0 : int
  rescue StandardError
    0
  end

  def car_present?(plate)
    @parking_spots.values.any? do |cars|
      cars.any? { |car| car[:plate] == plate }
    end
  end

  def find_spot_for(car_size)
    case car_size
    when 'small'
      return :small if @small.positive?
      return :medium if @medium.positive?
      return :large if @large.positive?
    when 'medium'
      return :medium if @medium.positive?
      return :large if @large.positive?
    when 'large'
      return :large if @large.positive?
    end

    nil
  end

  def park_in(spot_type, plate, size)
    @parking_spots[spot_type] << { plate: plate, size: size }
    decrement_spot(spot_type)

    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def try_shuffle_for(car_size)
    return false unless car_size == 'large'

    plan = plan_free_spot(:large, [])
    return false if plan.nil? || plan.empty?

    plan.each { |move| move_car(move[:car], move[:from], move[:to]) }
    true
  end

  def plan_free_spot(spot_type, freezing)
    return [] if available_count(spot_type).positive?
    return nil if freezing.include?(spot_type) || freezing.size >= 3

    current_freezing = freezing + [spot_type]

    movable_candidates(spot_type).each do |car|
      alternative_spots_for(car[:size]).each do |alternative_spot|
        next if alternative_spot == spot_type
        next if current_freezing.include?(alternative_spot)

        if available_count(alternative_spot).positive?
          return [{ car: car, from: spot_type, to: alternative_spot }]
        end

        nested_plan = plan_free_spot(alternative_spot, current_freezing)
        if nested_plan
          return nested_plan + [{ car: car, from: spot_type, to: alternative_spot }]
        end
      end
    end

    nil
  end

  def movable_candidates(spot_type)
    cars = @parking_spots[spot_type].select do |car|
      car[:size] == 'small' || car[:size] == 'medium'
    end

    if spot_type == :large
      cars.sort_by { |car| car[:size] == 'medium' ? 0 : 1 }
    else
      cars.sort_by { |car| car[:size] == 'small' ? 0 : 1 }
    end
  end

  def alternative_spots_for(car_size)
    case car_size
    when 'small' then [:small, :medium, :large]
    when 'medium' then [:medium, :large]
    else []
    end
  end

  def move_car(car, from, to)
    return unless @parking_spots.key?(from) && @parking_spots.key?(to)
    return unless @parking_spots[from].include?(car)

    @parking_spots[from].delete(car)
    increment_spot(from)

    @parking_spots[to] << car
    decrement_spot(to)
  end

  def available_count(spot_type)
    case spot_type
    when :small then @small
    when :medium then @medium
    when :large then @large
    else 0
    end
  end

  def increment_spot(spot_type)
    case spot_type
    when :small
      @small = [@small + 1, @total_small].min
    when :medium
      @medium = [@medium + 1, @total_medium].min
    when :large
      @large = [@large + 1, @total_large].min
    end
  end

  def decrement_spot(spot_type)
    case spot_type
    when :small
      @small = [@small - 1, 0].max
    when :medium
      @medium = [@medium - 1, 0].max
    when :large
      @large = [@large - 1, 0].max
    end
  end
end

class ParkingTicket
  include ParkingNormalization

  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = normalize_plate(license_plate)
    @car_size = normalize_size(car_size)
    @entry_time = coerce_time(entry_time)
  end

  def duration_hours
    diff = (Time.now - @entry_time).to_f / 3600.0
    diff.positive? ? diff : 0.0
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.hex(8)}"
  end

  def coerce_time(value)
    case value
    when Time then value
    when Numeric then Time.at(value)
    else Time.now
    end
  rescue StandardError
    Time.now
  end
end

class ParkingFeeCalculator
  include ParkingNormalization

  GRACE_PERIOD_HOURS = 0.25

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

  def calculate_fee(car_size, duration_hours)
    size = normalize_size(car_size)
    return 0.0 unless size && RATES.key?(size)

    duration = to_float(duration_hours)
    return 0.0 unless duration && duration.finite? && duration.positive?
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    billable_hours = (duration - GRACE_PERIOD_HOURS).ceil
    total = billable_hours * RATES[size]

    [total, DAILY_MAXIMUMS[size]].min.to_f
  end

  private

  def to_float(value)
    return value.to_f if value.is_a?(Numeric)

    Float(value.to_s.strip)
  rescue StandardError
    nil
  end
end

class ParkingGarageManager
  include ParkingNormalization

  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(small_spots = 0, medium_spots = nil, large_spots = nil, **options)
    small, medium, large = extract_spot_counts(small_spots, medium_spots, large_spots, options)

    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    return { success: false, message: 'Invalid license plate' } if normalized_plate.empty?

    normalized_size = normalize_size(size)
    return { success: false, message: 'Invalid car size' } unless normalized_size

    if @active_tickets.key?(normalized_plate)
      return { success: false, message: "car with license plate no. #{normalized_plate} is already parked" }
    end

    result = @garage.admit_car(normalized_plate, normalized_size)

    if result.is_a?(String) && result.include?('is parked at')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket

      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    return { success: false, message: 'Invalid license plate' } if normalized_plate.empty?

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: "No active ticket for license plate no. #{normalized_plate}" } unless ticket

    garage_result = @garage.exit_car(normalized_plate)

    unless garage_result.is_a?(String) && garage_result.include?('exited')
      return { success: false, message: garage_result }
    end

    @active_tickets.delete(normalized_plate)

    duration = ticket.duration_hours.to_f
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)

    { success: true, message: garage_result, fee: fee, duration_hours: duration }
  end

  def garage_status
    small_available = @garage.small
    medium_available = @garage.medium
    large_available = @garage.large

    {
      small_available: small_available,
      medium_available: medium_available,
      large_available: large_available,
      total_occupied: @garage.total_occupied,
      total_available: small_available + medium_available + large_available
    }
  end

  def find_ticket(plate)
    @active_tickets[normalize_plate(plate)]
  end

  private

  def extract_spot_counts(first, second, third, options)
    if first.is_a?(Hash)
      [
        count_from_hash(first, :small_spots, :small) || 0,
        count_from_hash(first, :medium_spots, :medium) || 0,
        count_from_hash(first, :large_spots, :large) || 0
      ]
    elsif options && !options.empty?
      [
        count_from_hash(options, :small_spots, :small) || first || 0,
        count_from_hash(options, :medium_spots, :medium) || second || 0,
        count_from_hash(options, :large_spots, :large) || third || 0
      ]
    else
      [first || 0, second || 0, third || 0]
    end
  end

  def count_from_hash(hash, *keys)
    keys.each do |key|
      if hash.key?(key)
        value = hash[key]
        return value unless value.nil?
      end

      string_key = key.to_s
      if hash.key?(string_key)
        value = hash[string_key]
        return value unless value.nil?
      end
    end

    nil
  end
end