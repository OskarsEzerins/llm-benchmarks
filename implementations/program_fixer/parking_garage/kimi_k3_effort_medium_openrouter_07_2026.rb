require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze
  SPOT_KEYS = { 'small' => :small, 'medium' => :medium, 'large' => :large }.freeze

  attr_reader :parking_spots, :small, :medium, :large

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
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)
    return parking_status if plate.empty? || size.nil?

    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)

    small_car  = @parking_spots[:small].detect  { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium].detect { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large].detect  { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      exit_status(plate)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      exit_status(plate)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      exit_status(plate)
    else
      exit_status
    end
  end

  def shuffle_medium(kar)
    # Move a small car out of a medium spot into a small spot if possible
    victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
    if victim && @small > 0
      @parking_spots[:medium].delete(victim)
      @parking_spots[:small] << victim
      @small -= 1
      @parking_spots[:medium] << kar
      parking_status(kar, 'medium')
    else
      parking_status
    end
  end

  def shuffle_large(kar)
    # Move a medium car out of a large spot into a medium spot if possible
    first_medium = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large].delete(first_medium)
      @parking_spots[:medium] << first_medium
      @medium -= 1
      @parking_spots[:large] << kar
      parking_status(kar, 'large')
    else
      # Try moving a small car from large spot to a small or medium spot
      first_small = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if first_small && @small > 0
        @parking_spots[:large].delete(first_small)
        @parking_spots[:small] << first_small
        @small -= 1
        @parking_spots[:large] << kar
        parking_status(kar, 'large')
      elsif first_small && @medium > 0
        @parking_spots[:large].delete(first_small)
        @parking_spots[:medium] << first_small
        @medium -= 1
        @parking_spots[:large] << kar
        parking_status(kar, 'large')
      else
        parking_status
      end
    end
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
      'car not found'
    end
  end

  private

  def normalize_plate(plate)
    plate.to_s.strip
  end

  def normalize_size(size)
    s = size.to_s.strip.downcase
    VALID_SIZES.include?(s) ? s : nil
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase.strip
    @entry_time    = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(2)
  end

  def valid?
    (Time.now - @entry_time) / 3600.0 <= 24.0
  end

  private

  def generate_ticket_id
    SecureRandom.uuid
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
    size = car_size.to_s.downcase.strip
    return 0.0 unless RATES.key?(size)

    duration = begin
      Float(duration_hours)
    rescue ArgumentError, TypeError
      return 0.0
    end
    return 0.0 if duration.negative? || duration <= GRACE_PERIOD_HOURS

    billable_hours = duration.ceil
    total = billable_hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets        = {}
  end

  def admit_car(plate, size)
    normalized_plate = plate.to_s.strip
    normalized_size  = size.to_s.strip.downcase

    unless %w[small medium large].include?(normalized_size)
      return { success: false, message: 'Invalid car size', ticket: nil }
    end

    if normalized_plate.empty?
      return { success: false, message: 'Invalid license plate', ticket: nil }
    end

    result = @garage.admit_car(normalized_plate, normalized_size)

    if result.include?('is parked at')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @tickets[normalized_plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result, ticket: nil }
    end
  end

  def exit_car(plate)
    normalized_plate = plate.to_s.strip
    ticket = @tickets[normalized_plate]
    return { success: false, message: 'No active ticket for this car', fee: 0.0, duration_hours: 0.0 } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(normalized_plate)

    @tickets.delete(normalized_plate)
    { success: true, message: result, fee: fee.to_f, duration_hours: duration }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @tickets.size,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s.strip]
  end

  def active_tickets
    @tickets.dup
  end
end