require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

  SPOT_FOR_SIZE = {
    'small'  => :small_spot,
    'medium' => :medium_spot,
    'large'  => :large_spot
  }.freeze

  SIZE_FOR_SPOT = {
    small_spot:  'small',
    medium_spot: 'medium',
    large_spot:  'large'
  }.freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small = 0, medium = 0, large = 0)
    @small  = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large  = [large.to_i, 0].max

    @parking_spots = {
      small_spot:  [],
      medium_spot: [],
      large_spot:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)

    return parking_status if plate.nil? || size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        park(car, :small_spot)
      elsif @medium > 0
        park(car, :medium_spot)
      elsif @large > 0
        park(car, :large_spot)
      else
        parking_status
      end
    when 'medium'
      if @medium > 0
        park(car, :medium_spot)
      elsif @large > 0
        park(car, :large_spot)
      else
        shuffle_medium(car)
      end
    when 'large'
      if @large > 0
        park(car, :large_spot)
      else
        shuffle_large(car)
      end
    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status if plate.nil?

    @parking_spots.each do |spot, cars|
      car = cars.find { |c| c[:plate].to_s == plate }
      next unless car

      cars.delete(car)
      free_spot(spot)
      return exit_status(plate)
    end

    exit_status(plate, false)
  end

  def occupied_count
    @parking_spots.values.map(&:size).reduce(0, :+)
  end

  def available_count
    @small + @medium + @large
  end

  def shuffle_medium(car)
    # Try to relocate a small car that occupies a medium or large spot
    [:medium_spot, :large_spot].each do |spot|
      victim = @parking_spots[spot].find { |c| c[:size] == 'small' }
      next unless victim
      next unless @small > 0

      @parking_spots[spot].delete(victim)
      @parking_spots[:small_spot] << victim
      @small -= 1

      @parking_spots[spot] << car
      return parking_status(car, SIZE_FOR_SPOT[spot])
    end

    parking_status
  end

  def shuffle_large(car)
    victim = nil
    target = nil

    medium_victim = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    small_victim  = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }

    if medium_victim && @medium > 0
      victim = medium_victim
      target = :medium_spot
    elsif small_victim && @small > 0
      victim = small_victim
      target = :small_spot
    elsif small_victim && @medium > 0
      victim = small_victim
      target = :medium_spot
    end

    return parking_status unless victim && target

    @parking_spots[:large_spot].delete(victim)
    @parking_spots[target] << victim
    case target
    when :small_spot  then @small  -= 1
    when :medium_spot then @medium -= 1
    end

    @parking_spots[:large_spot] << car
    parking_status(car, 'large')
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil, found = true)
    if plate && found
      "car with license plate no. #{plate} exited"
    elsif plate
      "car with license plate no. #{plate} not found"
    else
      'No car found'
    end
  end

  private

  def park(car, spot)
    @parking_spots[spot] << car
    case spot
    when :small_spot  then @small  -= 1
    when :medium_spot then @medium -= 1
    when :large_spot  then @large  -= 1
    end
    parking_status(car, SIZE_FOR_SPOT[spot])
  end

  def free_spot(spot)
    case spot
    when :small_spot  then @small  += 1
    when :medium_spot then @medium += 1
    when :large_spot  then @large  += 1
    end
  end

  def normalize_plate(plate)
    return nil if plate.nil?

    str = plate.to_s.strip
    str.empty? ? nil : str
  end

  def normalize_size(size)
    return nil if size.nil?

    str = size.to_s.strip.downcase
    VALID_SIZES.include?(str) ? str : nil
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.strip.downcase
    @entry_time    = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    elapsed = (Time.now - @entry_time) / 3600.0
    elapsed.negative? ? 0.0 : elapsed
  end

  def valid?
    duration_hours <= 24.0
  end

  def to_h
    {
      id: @id,
      license_plate: @license_plate,
      car_size: @car_size,
      entry_time: @entry_time
    }
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

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    rate = RATES[size]
    return 0.0 if rate.nil?

    hours = safe_duration(duration_hours)
    return 0.0 if hours.nil?
    return 0.0 if hours <= GRACE_PERIOD_HOURS

    billable_hours = (hours - GRACE_PERIOD_HOURS).ceil
    billable_hours = 1 if billable_hours < 1

    total = billable_hours * rate
    [total.to_f, MAX_FEE[size]].min.to_f
  end

  def hourly_rate(car_size)
    RATES[car_size.to_s.strip.downcase] || 0.0
  end

  def daily_maximum(car_size)
    MAX_FEE[car_size.to_s.strip.downcase] || 0.0
  end

  private

  def safe_duration(value)
    return nil if value.nil?

    numeric = begin
      Float(value)
    rescue ArgumentError, TypeError
      nil
    end
    return nil if numeric.nil?
    return 0.0 if numeric.negative?

    numeric
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator

  def initialize(small_spots = 0, medium_spots = 0, large_spots = 0)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(license_plate, car_size)
    message = @garage.admit_car(license_plate, car_size)

    if message.to_s.include?('is parked at')
      plate  = license_plate.to_s.strip
      size   = car_size.to_s.strip.downcase
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(license_plate)
    plate  = license_plate.to_s.strip
    ticket = @active_tickets[plate]

    unless ticket
      return { success: false, message: "no active ticket found for license plate no. #{plate}" }
    end

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message  = @garage.exit_car(plate)

    @active_tickets.delete(plate)

    {
      success: true,
      message: message,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @garage.occupied_count,
      total_available:  @garage.available_count
    }
  end

  def find_ticket(license_plate)
    @active_tickets[license_plate.to_s.strip]
  end

  def active_tickets
    @active_tickets.values
  end

  def active_ticket_count
    @active_tickets.size
  end
end