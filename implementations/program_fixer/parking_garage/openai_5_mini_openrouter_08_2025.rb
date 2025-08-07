require 'securerandom'
require 'time'

class ParkingGarage
  attr_reader :capacity_small, :capacity_medium, :capacity_large, :parking_spots

  def initialize(small, medium, large)
    @capacity_small  = (small || 0).to_i
    @capacity_medium = (medium || 0).to_i
    @capacity_large  = (large || 0).to_i

    # spots hold hashes: { plate: 'ABC123', size: 'small' }
    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  # Admit a car; returns a descriptive string message.
  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)
    return "Invalid license plate" if plate.nil? || plate.strip == ''
    return "Invalid car size" unless %w[small medium large].include?(size)

    case size
    when 'small'
      if small_available > 0
        @parking_spots[:small] << { plate: plate, size: size }
        return "car with license plate no. #{plate} is parked at small"
      elsif medium_available > 0
        @parking_spots[:medium] << { plate: plate, size: size }
        return "car with license plate no. #{plate} is parked at medium"
      elsif large_available > 0
        @parking_spots[:large] << { plate: plate, size: size }
        return "car with license plate no. #{plate} is parked at large"
      else
        return "No space available"
      end

    when 'medium'
      if medium_available > 0
        @parking_spots[:medium] << { plate: plate, size: size }
        return "car with license plate no. #{plate} is parked at medium"
      elsif large_available > 0
        @parking_spots[:large] << { plate: plate, size: size }
        return "car with license plate no. #{plate} is parked at large"
      else
        # try to shuffle: move a small from medium to small (if any) to free medium
        if shuffle_to_free_medium
          @parking_spots[:medium] << { plate: plate, size: size }
          return "car with license plate no. #{plate} is parked at medium"
        end
        return "No space available"
      end

    when 'large'
      if large_available > 0
        @parking_spots[:large] << { plate: plate, size: size }
        return "car with license plate no. #{plate} is parked at large"
      else
        # Try shuffling: find a medium currently in large, move it to medium if space
        moved = shuffle_large_to_make_space
        if moved && large_available > 0
          @parking_spots[:large] << { plate: plate, size: size }
          return "car with license plate no. #{plate} is parked at large"
        end
        return "No space available"
      end
    end
  end

  # Exit a car; returns descriptive string.
  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return "Invalid license plate" if plate.nil? || plate.strip == ''

    [:small, :medium, :large].each do |spot_type|
      car = @parking_spots[spot_type].find { |c| c[:plate] == plate }
      if car
        @parking_spots[spot_type].delete(car)
        return "car with license plate no. #{plate} exited"
      end
    end

    "No such car parked"
  end

  def small_available
    @capacity_small - @parking_spots[:small].length
  end

  def medium_available
    @capacity_medium - @parking_spots[:medium].length
  end

  def large_available
    @capacity_large - @parking_spots[:large].length
  end

  def total_occupied
    @parking_spots.values.map(&:length).sum
  end

  def total_capacity
    @capacity_small + @capacity_medium + @capacity_large
  end

  def total_available
    total_capacity - total_occupied
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?
    plate.to_s
  end

  def normalize_size(size)
    return nil if size.nil?
    size.to_s.strip.downcase
  end

  # For medium admission: attempt to free a medium spot by moving a small from medium to small spot
  def shuffle_to_free_medium
    # find a small parked in medium spot
    victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
    return false unless victim
    return false unless small_available > 0

    @parking_spots[:medium].delete(victim)
    @parking_spots[:small] << victim
    true
  end

  # For large admission when full: attempt to move a medium car from large to medium spot (if medium spot available)
  def shuffle_large_to_make_space
    # find a medium parked in large
    victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    return false unless victim
    return false unless medium_available > 0

    @parking_spots[:large].delete(victim)
    @parking_spots[:medium] << victim
    true
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = (car_size || '').to_s.strip.downcase
    @entry_time    = entry_time || Time.now
  end

  def duration_hours
    diff_seconds = Time.now - @entry_time
    return 0.0 if diff_seconds < 0
    diff_seconds / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  HOURLY_RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }.freeze

  MAX_DAILY = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = (car_size || '').to_s.strip.downcase
    return 0.0 unless HOURLY_RATES.key?(size)
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours <= 0.0
    return 0.0 if duration_hours <= GRACE_PERIOD_HOURS

    chargeable = duration_hours - GRACE_PERIOD_HOURS
    hours_to_charge = chargeable.ceil
    total = hours_to_charge * HOURLY_RATES[size]
    max_fee = MAX_DAILY[size] || total
    [[total, max_fee].min, 0.0].max.to_f
  end
end

class ParkingGarageManager
  def initialize(*args, **kwargs)
    # Support both positional (small, medium, large) and keyword arguments
    if args.length == 3
      small_spots, medium_spots, large_spots = args
    else
      small_spots  = kwargs.fetch(:small_spots, kwargs.fetch(:small, 0))
      medium_spots = kwargs.fetch(:medium_spots, kwargs.fetch(:medium, 0))
      large_spots  = kwargs.fetch(:large_spots, kwargs.fetch(:large, 0))
    end

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {} # key: plate string -> ParkingTicket
  end

  # Admit car and generate ticket on success
  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)
    return { success: false, message: 'Invalid license plate' } if plate.nil? || plate.strip == ''
    return { success: false, message: 'Invalid car size' } unless %w[small medium large].include?(size)

    result = @garage.admit_car(plate, size)
    if result.to_s.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  # Exit car, calculate fee, and remove ticket
  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return { success: false, message: 'Invalid license plate' } if plate.nil? || plate.strip == ''

    ticket = @tickets[plate]
    return { success: false, message: "No active ticket for #{plate}" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    garage_message = @garage.exit_car(plate)
    @tickets.delete(plate)

    { success: true, message: garage_message, fee: fee.to_f, duration_hours: duration }
  end

  def garage_status
    {
      small_available:  @garage.small_available,
      medium_available: @garage.medium_available,
      large_available:  @garage.large_available,
      total_occupied:   @garage.total_occupied,
      total_available:  @garage.total_available
    }
  end

  def find_ticket(license_plate_no)
    plate = normalize_plate(license_plate_no)
    @tickets.fetch(plate, nil)
  end

  private

  def normalize_plate(p)
    return nil if p.nil?
    p.to_s
  end

  def normalize_size(s)
    return nil if s.nil?
    s.to_s.strip.downcase
  end
end