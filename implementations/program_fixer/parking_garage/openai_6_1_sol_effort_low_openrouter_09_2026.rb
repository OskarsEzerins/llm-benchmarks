require 'securerandom'

module ParkingValidation
  SIZES = %w[small medium large].freeze

  def self.plate(value)
    return nil if value.nil?

    plate = value.to_s.strip
    plate.empty? ? nil : plate
  end

  def self.size(value)
    return nil if value.nil?

    size = value.to_s.strip.downcase
    SIZES.include?(size) ? size : nil
  end

  def self.capacity(value)
    [Integer(value), 0].max
  rescue ArgumentError, TypeError, RangeError
    0
  end
end

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = ParkingValidation.capacity(small)
    @medium = ParkingValidation.capacity(medium)
    @large = ParkingValidation.capacity(large)

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = ParkingValidation.plate(license_plate_no)
    size = ParkingValidation.size(car_size)

    return 'Invalid license plate' unless plate
    return 'Invalid car size' unless size
    return 'Car is already parked' if parked?(plate)

    car = { plate: plate, size: size }
    eligible_spots(size).each do |spot|
      return park(car, spot) if available(spot).positive?
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
    plate = ParkingValidation.plate(license_plate_no)
    return 'Invalid license plate' unless plate

    ParkingValidation::SIZES.each do |spot|
      cars = @parking_spots[spot_key(spot)]
      car = cars.find { |candidate| candidate[:plate] == plate }
      next unless car

      cars.delete(car)
      adjust_available(spot, 1)
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    %w[medium large].each do |spot|
      return park(car, spot) if free_spot(spot)
    end
    parking_status
  end

  def shuffle_large(car)
    return park(car, 'large') if free_spot('large')

    parking_status
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

  def spot_key(spot)
    :"#{spot}_spot"
  end

  def available(spot)
    instance_variable_get("@#{spot}")
  end

  def adjust_available(spot, amount)
    instance_variable_set("@#{spot}", available(spot) + amount)
  end

  def eligible_spots(size)
    ParkingValidation::SIZES.drop(ParkingValidation::SIZES.index(size))
  end

  def parked?(plate)
    @parking_spots.values.any? do |cars|
      cars.any? { |car| car[:plate] == plate }
    end
  end

  def park(car, spot)
    @parking_spots[spot_key(spot)] << car
    adjust_available(spot, -1)
    parking_status(car, spot)
  end

  # Relocate only into smaller compatible spots, including chained moves.
  def free_spot(spot)
    return true if available(spot).positive?

    spot_index = ParkingValidation::SIZES.index(spot)
    @parking_spots[spot_key(spot)].dup.each do |car|
      eligible_spots(car[:size]).each do |destination|
        next unless ParkingValidation::SIZES.index(destination) < spot_index
        next unless free_spot(destination)

        @parking_spots[spot_key(spot)].delete(car)
        adjust_available(spot, 1)
        @parking_spots[spot_key(destination)] << car
        adjust_available(destination, -1)
        return true
      end
    end

    false
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  alias license_plate_no license_plate
  alias ticket_id id

  def initialize(license_plate, car_size, entry_time = Time.now)
    @license_plate = ParkingValidation.plate(license_plate)
    @car_size = ParkingValidation.size(car_size)
    @entry_time = entry_time
    @id = generate_ticket_id
  end

  def duration_hours(now = Time.now)
    return 0.0 unless @entry_time.is_a?(Time) && now.is_a?(Time)

    [(now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?(now = Time.now)
    return false unless @license_plate && @car_size
    return false unless @entry_time.is_a?(Time) && now.is_a?(Time)

    elapsed = now - @entry_time
    elapsed >= 0 && elapsed <= 24 * 3600
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = ParkingValidation.size(car_size)
    return 0.0 unless size
    return 0.0 unless duration_hours.is_a?(Numeric) || duration_hours.is_a?(String)

    duration = Float(duration_hours)
    return 0.0 unless duration.finite? && duration > GRACE_PERIOD

    [duration.ceil * RATES[size], MAX_FEE[size]].min.to_f
  rescue ArgumentError, TypeError, RangeError
    0.0
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(small = 0, medium = 0, large = 0, **options)
    small = options.fetch(:small_spots, small)
    medium = options.fetch(:medium_spots, medium)
    large = options.fetch(:large_spots, large)

    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = ParkingValidation.plate(plate)
    normalized_size = ParkingValidation.size(size)

    return { success: false, message: 'Invalid license plate' } unless normalized_plate
    return { success: false, message: 'Invalid car size' } unless normalized_size

    if @active_tickets.key?(normalized_plate)
      return { success: false, message: 'Car is already parked' }
    end

    message = @garage.admit_car(normalized_plate, normalized_size)
    unless message.start_with?('car with license plate no.')
      return { success: false, message: message }
    end

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @active_tickets[normalized_plate] = ticket
    { success: true, message: message, ticket: ticket }
  end

  def exit_car(plate)
    normalized_plate = ParkingValidation.plate(plate)
    return { success: false, message: 'Invalid license plate' } unless normalized_plate

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'Car not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    unless message == "car with license plate no. #{normalized_plate} exited"
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
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.parking_spots.values.sum(&:length),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    normalized_plate = ParkingValidation.plate(plate)
    normalized_plate ? @active_tickets[normalized_plate] : nil
  end
end