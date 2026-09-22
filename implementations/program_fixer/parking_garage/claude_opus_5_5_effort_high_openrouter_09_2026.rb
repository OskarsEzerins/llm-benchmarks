require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
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
        @parking_spots[:small_spot] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_medium(car)
      end
    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
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

    small_car  = @parking_spots[:small_spot].find  { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium_spot].find { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large_spot].find  { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      exit_status(plate)
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      exit_status(plate)
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      exit_status(plate)
    else
      exit_status
    end
  end

  def parked?(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return false if plate.nil?

    @parking_spots.values.any? { |cars| cars.any? { |c| c[:plate] == plate } }
  end

  def total_occupied
    @parking_spots.values.sum(&:size)
  end

  def shuffle_medium(car)
    # Medium and large spots are full: move a small car occupying a
    # medium/large spot into a free small spot, then take its place.
    return parking_status unless @small > 0

    [:medium_spot, :large_spot].each do |where|
      victim = @parking_spots[where].find { |c| c[:size] == 'small' }
      next unless victim

      @parking_spots[where].delete(victim)
      @parking_spots[:small_spot] << victim
      @small -= 1
      @parking_spots[where] << car
      return parking_status(car, where.to_s.sub('_spot', ''))
    end

    parking_status
  end

  def shuffle_large(car)
    # Large spots are full: move a medium car from a large spot into a free medium spot
    if @medium > 0
      first_medium = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
      if first_medium
        @parking_spots[:large_spot].delete(first_medium)
        @parking_spots[:medium_spot] << first_medium
        @medium -= 1
        @parking_spots[:large_spot] << car
        return parking_status(car, 'large')
      end
    end

    # Otherwise move a small car from a large spot into a free small/medium spot
    first_small = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
    if first_small
      if @small > 0
        @parking_spots[:large_spot].delete(first_small)
        @parking_spots[:small_spot] << first_small
        @small -= 1
        @parking_spots[:large_spot] << car
        return parking_status(car, 'large')
      elsif @medium > 0
        @parking_spots[:large_spot].delete(first_small)
        @parking_spots[:medium_spot] << first_small
        @medium -= 1
        @parking_spots[:large_spot] << car
        return parking_status(car, 'large')
      end
    end

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
    plate ? "car with license plate no. #{plate} exited" : 'Ghost car?'
  end

  private

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
  attr_reader :id, :license_plate, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.strip.downcase
    @entry_time    = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.nil? ? nil : car_size.to_s.strip.downcase
    rate = RATES[size]
    return 0.0 if rate.nil?

    duration = to_float(duration_hours)
    return 0.0 if duration.nil? || duration.nan? || duration.infinite? || duration <= 0
    return 0.0 if duration <= GRACE_PERIOD

    hours = (duration - GRACE_PERIOD).ceil
    total = hours * rate
    [total, MAX_FEE[size]].min.to_f
  end

  private

  def to_float(value)
    return nil if value.nil?
    return value.to_f if value.is_a?(Numeric)

    Float(value)
  rescue ArgumentError, TypeError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    key = plate.nil? ? nil : plate.to_s.strip

    if key.nil? || key.empty?
      return { success: false, message: 'Invalid license plate' }
    end

    if @active_tickets.key?(key) || @garage.parked?(key)
      return { success: false, message: "car with license plate no. #{key} is already parked" }
    end

    verdict = @garage.admit_car(key, size)

    if verdict.to_s.include?('is parked at')
      ticket = ParkingTicket.new(key, size.to_s.strip.downcase)
      @active_tickets[key] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    key = plate.nil? ? nil : plate.to_s.strip
    ticket = key.nil? || key.empty? ? nil : @active_tickets[key]
    return { success: false, message: 'No active ticket found' } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(key)

    @active_tickets.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    small_available  = @garage.small
    medium_available = @garage.medium
    large_available  = @garage.large

    {
      small_available:  small_available,
      medium_available: medium_available,
      large_available:  large_available,
      total_occupied:   @garage.total_occupied,
      total_available:  small_available + medium_available + large_available
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?

    @active_tickets.fetch(plate.to_s.strip, nil)
  end

  def active_tickets
    @active_tickets.values
  end
end