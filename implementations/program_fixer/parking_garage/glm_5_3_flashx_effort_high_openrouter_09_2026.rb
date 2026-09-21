require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  VALID_SIZES = %w[small medium large].freeze

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size  = car_size.to_s.downcase.strip

    return no_space_message if plate.empty? || !VALID_SIZES.include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small.positive?
        park_car(car, :small)
      elsif @medium.positive?
        park_car(car, :medium)
      elsif @large.positive?
        park_car(car, :large)
      else
        no_space_message
      end
    when 'medium'
      if @medium.positive?
        park_car(car, :medium)
      elsif @large.positive?
        park_car(car, :large)
      else
        no_space_message
      end
    when 'large'
      if @large.positive?
        park_car(car, :large)
      elsif shuffle_for_large_car
        park_car(car, :large)
      else
        no_space_message
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s

    spot_key = @parking_spots.keys.find do |key|
      @parking_spots[key].any? { |c| c[:plate] == plate }
    end

    if spot_key
      car = @parking_spots[spot_key].delete_at(
        @parking_spots[spot_key].index { |c| c[:plate] == plate }
      )
      case spot_key
      when :small  then @small  += 1
      when :medium then @medium += 1
      when :large  then @large  += 1
      end
      "car with license plate no. #{car[:plate]} exited"
    else
      "car with license plate no. #{plate} not found"
    end
  end

  def occupied_count
    @parking_spots.values.map(&:length).sum
  end

  private

  def park_car(car, spot_type)
    @parking_spots[spot_type] << car
    case spot_type
    when :small  then @small  -= 1
    when :medium then @medium -= 1
    when :large  then @large  -= 1
    end
    "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
  end

  # Move a medium car out of a large spot into a free medium spot
  # so a large car can take the large spot.
  def shuffle_for_large_car
    return false unless @medium.positive?

    victim_index = @parking_spots[:large].index { |c| c[:size] == 'medium' }
    return false unless victim_index

    victim = @parking_spots[:large].delete_at(victim_index)
    @parking_spots[:medium] << victim
    @medium -= 1
    @large += 1
    true
  end

  def no_space_message
    'No space available'
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id             = SecureRandom.uuid
    @license_plate  = license_plate.to_s
    @car_size       = car_size.to_s.downcase
    @entry_time     = entry_time
  end

  def duration_hours
    (Time.now - entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours.negative?

    return 0.0 if duration_hours <= GRACE_PERIOD

    billable_hours = (duration_hours - GRACE_PERIOD).ceil
    rate = RATES[size]
    max  = MAX_FEE[size]

    fee = billable_hours * rate
    [fee, max].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
    @capacities     = {
      small:  small_spots.to_i,
      medium: medium_spots.to_i,
      large:  large_spots.to_i
    }
  end

  def admit_car(license_plate, car_size)
    result = @garage.admit_car(license_plate, car_size)

    if result.to_s.include?('parked')
      ticket = ParkingTicket.new(license_plate, car_size)
      @active_tickets[license_plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result, ticket: nil }
    end
  end

  def exit_car(license_plate)
    plate  = license_plate.to_s
    ticket = @active_tickets[plate]

    return { success: false, message: "car with license plate no. #{plate} not found", fee: 0.0, duration_hours: 0.0 } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(plate)

    @active_tickets.delete(plate)

    if result.to_s.include?('exited')
      { success: true, message: result, fee: fee, duration_hours: duration }
    else
      { success: false, message: result, fee: fee, duration_hours: duration }
    end
  end

  def garage_status
    small_available  = @garage.small
    medium_available = @garage.medium
    large_available  = @garage.large

    total_available = small_available + medium_available + large_available
    total_capacity  = @capacities.values.sum

    {
      small_available:  small_available,
      medium_available: medium_available,
      large_available:  large_available,
      total_occupied:   total_capacity - total_available,
      total_available:  total_available
    }
  end

  def find_ticket(license_plate)
    @active_tickets[license_plate.to_s]
  end
end