require 'securerandom'

module ParkingInputValidation
  VALID_CAR_SIZES = %w[small medium large].freeze

  def normalize_license_plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  end

  def normalize_car_size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    VALID_CAR_SIZES.include?(size) ? size : nil
  end
end

class ParkingGarage
  include ParkingInputValidation

  attr_reader :parking_spots, :small, :medium, :large

  SPOTS = %i[small medium large].freeze

  SPOT_RANK = {
    small: 0,
    medium: 1,
    large: 2
  }.freeze

  SIZE_RANK = {
    'small' => 0,
    'medium' => 1,
    'large' => 2
  }.freeze

  PREFERRED_SPOTS = {
    'small' => %i[small medium large],
    'medium' => %i[medium large],
    'large' => %i[large]
  }.freeze

  def initialize(small, medium, large)
    @capacities = {
      small: sanitized_count(small),
      medium: sanitized_count(medium),
      large: sanitized_count(large)
    }

    @small = @capacities[:small]
    @medium = @capacities[:medium]
    @large = @capacities[:large]

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_license_plate(license_plate_no)
    size = normalize_car_size(car_size)

    return 'Invalid license plate' unless plate
    return 'Invalid car size' unless size
    return 'Car already parked' if parked_license?(plate)

    car = {
      plate: plate,
      license_plate_no: plate,
      license_plate: plate,
      size: size,
      car_size: size
    }

    PREFERRED_SPOTS[size].each do |spot|
      next unless available_count(spot).positive? || free_spot(spot)

      park_car(car, spot)
      return parking_status(car, spot.to_s)
    end

    parking_status
  end

  def exit_car(license_plate_no)
    plate = normalize_license_plate(license_plate_no)
    return 'Car not found' unless plate

    spot, car = find_parked_car(plate)
    return 'Car not found' unless car

    @parking_spots[spot].delete(car)
    increment_available(spot)

    exit_status(plate)
  end

  def occupied_count
    SPOTS.sum { |spot| @parking_spots[spot].size }
  end

  def available_count(spot)
    case spot.to_sym
    when :small
      @small
    when :medium
      @medium
    when :large
      @large
    else
      0
    end
  end

  def total_available
    @small + @medium + @large
  end

  def total_capacity
    @capacities.values.sum
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : 'Car not found'
  end

  private

  def sanitized_count(value)
    count = begin
      Integer(value)
    rescue StandardError
      0
    end

    [count, 0].max
  end

  def parked_license?(plate)
    !!find_parked_car(plate).last
  end

  def find_parked_car(plate)
    SPOTS.each do |spot|
      car = @parking_spots[spot].find { |parked_car| parked_car[:plate] == plate }
      return [spot, car] if car
    end

    [nil, nil]
  end

  def park_car(car, spot)
    car[:spot_type] = spot.to_s
    @parking_spots[spot] << car
    decrement_available(spot)
  end

  def move_car(from_spot, to_spot, car)
    return if from_spot == to_spot

    @parking_spots[from_spot].delete(car)
    increment_available(from_spot)

    car[:spot_type] = to_spot.to_s
    @parking_spots[to_spot] << car
    decrement_available(to_spot)
  end

  def increment_available(spot)
    case spot
    when :small
      @small = [@small + 1, @capacities[:small]].min
    when :medium
      @medium = [@medium + 1, @capacities[:medium]].min
    when :large
      @large = [@large + 1, @capacities[:large]].min
    end
  end

  def decrement_available(spot)
    case spot
    when :small
      @small = [@small - 1, 0].max
    when :medium
      @medium = [@medium - 1, 0].max
    when :large
      @large = [@large - 1, 0].max
    end
  end

  def free_spot(target_spot)
    return true if available_count(target_spot).positive?

    target_rank = SPOT_RANK[target_spot]
    return false if target_rank.nil? || target_spot == :small

    movable_cars = @parking_spots[target_spot]
                   .select { |car| SIZE_RANK[car[:size]] && SIZE_RANK[car[:size]] < target_rank }
                   .sort_by { |car| SIZE_RANK[car[:size]] }

    movable_cars.each do |car|
      PREFERRED_SPOTS[car[:size]].each do |destination|
        next unless SPOT_RANK[destination] < target_rank
        next unless available_count(destination).positive? || free_spot(destination)

        move_car(target_spot, destination, car)
        return true
      end
    end

    false
  end
end

class ParkingTicket
  include ParkingInputValidation

  attr_reader :id,
              :ticket_id,
              :entry_time,
              :license_plate,
              :license_plate_no,
              :car_size

  @sequence = 0
  @sequence_mutex = Mutex.new

  class << self
    def generate_ticket_id
      @sequence_mutex.synchronize do
        @sequence += 1
        "TK-#{@sequence}-#{SecureRandom.hex(8)}"
      end
    end
  end

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = self.class.generate_ticket_id
    @ticket_id = @id
    @license_plate = normalize_license_plate(license_plate) || license_plate.to_s
    @license_plate_no = @license_plate
    @car_size = normalize_car_size(car_size) || car_size.to_s.strip.downcase
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours(current_time = Time.now)
    current = current_time.is_a?(Time) ? current_time : Time.now
    duration = (current - @entry_time) / 3600.0
    [duration, 0.0].max
  end

  def valid?(current_time = Time.now)
    duration_hours(current_time) <= 24.0
  end
end

class ParkingFeeCalculator
  include ParkingInputValidation

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

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = normalize_car_size(car_size)
    duration = normalized_duration(duration_hours)

    return 0.0 unless size
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    rate = RATES[size]
    daily_maximum = DAILY_MAXIMUMS[size]

    if duration <= 24.0
      return [(duration.ceil * rate).to_f, daily_maximum].min.to_f
    end

    full_days = (duration / 24.0).floor
    remainder = duration - (full_days * 24.0)

    total = full_days * daily_maximum

    if remainder > GRACE_PERIOD_HOURS
      total += [(remainder.ceil * rate).to_f, daily_maximum].min
    end

    total.to_f
  end

  private

  def normalized_duration(value)
    duration = begin
      Float(value)
    rescue StandardError
      0.0
    end

    return 0.0 unless duration.finite?

    [duration, 0.0].max
  end
end

class ParkingGarageManager
  include ParkingInputValidation

  attr_reader :garage, :active_tickets

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **kwargs)
    small_spots = kwargs[:small_spots] if kwargs.key?(:small_spots)
    medium_spots = kwargs[:medium_spots] if kwargs.key?(:medium_spots)
    large_spots = kwargs[:large_spots] if kwargs.key?(:large_spots)

    small_spots = kwargs[:small] if kwargs.key?(:small)
    medium_spots = kwargs[:medium] if kwargs.key?(:medium)
    large_spots = kwargs[:large] if kwargs.key?(:large)

    @garage = ParkingGarage.new(small_spots || 0, medium_spots || 0, large_spots || 0)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_license_plate(plate)
    normalized_size = normalize_car_size(size)

    return { success: false, message: 'Invalid license plate' } unless normalized_plate
    return { success: false, message: 'Invalid car size' } unless normalized_size
    return { success: false, message: 'Car already parked' } if @active_tickets.key?(normalized_plate)

    message = @garage.admit_car(normalized_plate, normalized_size)

    if message.start_with?("car with license plate no. #{normalized_plate} is parked at")
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
    normalized_plate = normalize_license_plate(plate)
    return { success: false, message: 'Invalid license plate' } unless normalized_plate

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'Ticket not found' } unless ticket

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
      total_occupied: @garage.occupied_count,
      total_available: @garage.total_available
    }
  end

  def find_ticket(plate)
    normalized_plate = normalize_license_plate(plate)
    return nil unless normalized_plate

    @active_tickets[normalized_plate]
  end
end