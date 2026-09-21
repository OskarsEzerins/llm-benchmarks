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
    plate = license_plate_no.to_s
    size  = car_size.to_s.downcase

    return 'No space available' if plate.strip.empty?
    return 'No space available' unless VALID_SIZES.include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        park_car(car, :small)
      elsif @medium > 0
        park_car(car, :medium)
      elsif @large > 0
        park_car(car, :large)
      else
        'No space available'
      end
    when 'medium'
      if @medium > 0
        park_car(car, :medium)
      elsif @large > 0
        park_car(car, :large)
      else
        'No space available'
      end
    when 'large'
      if @large > 0
        park_car(car, :large)
      elsif shuffle_for_large_car
        park_car(car, :large)
      else
        'No space available'
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s

    spot_type = @parking_spots.keys.find do |type|
      @parking_spots[type].any? { |c| c[:plate] == plate }
    end

    return "car with license plate no. #{plate} not found" unless spot_type

    car = @parking_spots[spot_type].detect { |c| c[:plate] == plate }
    @parking_spots[spot_type].delete(car)

    case spot_type
    when :small
      @small += 1
    when :medium
      @medium += 1
    when :large
      @large += 1
    end

    "car with license plate no. #{plate} exited"
  end

  def available_spots
    @small + @medium + @large
  end

  def occupied_spots
    @parking_spots.values.map(&:length).sum
  end

  private

  def park_car(car, spot_type)
    @parking_spots[spot_type] << car

    case spot_type
    when :small
      @small -= 1
    when :medium
      @medium -= 1
    when :large
      @large -= 1
    end

    "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
  end

  def shuffle_for_large_car
    medium_car_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    return false unless medium_car_in_large && @medium > 0

    @parking_spots[:large].delete(medium_car_in_large)
    @parking_spots[:medium] << medium_car_in_large
    @medium -= 1
    @large += 1
    true
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
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
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours.negative?

    size = car_size.to_s.downcase
    rate = RATES[size]
    return 0.0 unless rate

    billable_hours = (duration_hours - GRACE_PERIOD).ceil
    billable_hours = 0 if billable_hours.negative?

    total = billable_hours * rate
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  VALID_SIZES = %w[small medium large].freeze

  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @total_capacity = small_spots.to_i + medium_spots.to_i + large_spots.to_i
    @fee_calculator = ParkingFeeCalculator.new
    @tickets        = {}
  end

  def admit_car(license_plate, car_size)
    plate = license_plate.to_s
    size  = car_size.to_s.downcase

    if plate.strip.empty?
      return { success: false, message: 'Invalid license plate' }
    end

    unless VALID_SIZES.include?(size)
      return { success: false, message: 'Invalid car size' }
    end

    message = @garage.admit_car(plate, size)

    if message.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(license_plate)
    plate  = license_plate.to_s
    ticket = @tickets[plate]

    unless ticket
      return { success: false, message: "No active ticket for license plate no. #{plate}" }
    end

    message = @garage.exit_car(plate)

    if message.include?('exited')
      duration = ticket.duration_hours
      fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
      @tickets.delete(plate)
      { success: true, message: message, fee: fee, duration_hours: duration }
    else
      { success: false, message: message }
    end
  end

  def garage_status
    total_available = @garage.available_spots
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @total_capacity - total_available,
      total_available:  total_available
    }
  end

  def find_ticket(license_plate)
    @tickets[license_plate.to_s]
  end

  def active_ticket_count
    @tickets.size
  end
end