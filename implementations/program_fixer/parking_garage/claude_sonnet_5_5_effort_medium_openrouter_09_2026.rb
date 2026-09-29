require 'securerandom'

VALID_CAR_SIZES = %w[small medium large].freeze

def normalize_car_size(size)
  return nil if size.nil?
  s = size.to_s.strip.downcase
  VALID_CAR_SIZES.include?(s) ? s : nil
end

def normalize_plate(plate)
  return nil if plate.nil?
  p = plate.to_s.strip
  p.empty? ? nil : p
end

class ParkingGarage
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
    size  = normalize_car_size(car_size)
    return 'No space available' if plate.nil? || size.nil?

    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        place(kar, :small_spot)
      elsif @medium > 0
        place(kar, :medium_spot)
      elsif @large > 0
        place(kar, :large_spot)
      else
        parking_status
      end
    when 'medium'
      if @medium > 0
        place(kar, :medium_spot)
      elsif @large > 0
        place(kar, :large_spot)
      else
        shuffle_medium(kar)
      end
    when 'large'
      if @large > 0
        place(kar, :large_spot)
      else
        shuffle_large(kar)
      end
    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status if plate.nil?

    [:small_spot, :medium_spot, :large_spot].each do |spot|
      car = @parking_spots[spot].find { |c| c[:plate] == plate }
      next unless car
      @parking_spots[spot].delete(car)
      case spot
      when :small_spot  then @small += 1
      when :medium_spot then @medium += 1
      when :large_spot  then @large += 1
      end
      return exit_status(plate)
    end
    exit_status
  end

  def shuffle_medium(kar)
    # Try to move a small car out of a large spot into a free small/medium spot
    victim = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
    if victim
      if @small > 0
        move(victim, :large_spot, :small_spot)
      elsif @medium > 0
        move(victim, :large_spot, :medium_spot)
      end
      if @large > 0
        return place(kar, :large_spot)
      end
    end
    parking_status
  end

  def shuffle_large(kar)
    candidates = @parking_spots[:large_spot].select { |c| c[:size] != 'large' }
    candidates.sort_by! { |c| c[:size] == 'medium' ? 0 : 1 }
    candidates.each do |c|
      if c[:size] == 'medium' && @medium > 0
        move(c, :large_spot, :medium_spot)
        return place(kar, :large_spot)
      elsif c[:size] == 'small' && @small > 0
        move(c, :large_spot, :small_spot)
        return place(kar, :large_spot)
      elsif c[:size] == 'small' && @medium > 0
        move(c, :large_spot, :medium_spot)
        return place(kar, :large_spot)
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
    if plate
      "car with license plate no. #{plate} exited"
    else
      'No car found'
    end
  end

  private

  def place(kar, spot)
    @parking_spots[spot] << kar
    case spot
    when :small_spot  then @small -= 1
    when :medium_spot then @medium -= 1
    when :large_spot  then @large -= 1
    end
    parking_status(kar, spot.to_s.sub('_spot', ''))
  end

  def move(car, from, to)
    @parking_spots[from].delete(car)
    case from
    when :small_spot  then @small += 1
    when :medium_spot then @medium += 1
    when :large_spot  then @large += 1
    end
    @parking_spots[to] << car
    case to
    when :small_spot  then @small -= 1
    when :medium_spot then @medium -= 1
    when :large_spot  then @large -= 1
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.strip.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24
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
    size = normalize_car_size(car_size)
    return 0.0 if size.nil?
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours.respond_to?(:nan?) && duration_hours.nan?
    return 0.0 if duration_hours <= GRACE_PERIOD

    hours = duration_hours.ceil
    total = hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @active_tickets  = {}
    @total_spots     = @garage.small + @garage.medium + @garage.large
  end

  def admit_car(plate, size)
    key  = normalize_plate(plate)
    csz  = normalize_car_size(size)

    if key.nil? || csz.nil?
      return { success: false, message: 'No space available' }
    end

    if @active_tickets.key?(key)
      return { success: false, message: "car with license plate no. #{key} is already parked" }
    end

    verdict = @garage.admit_car(key, csz)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(key, csz)
      @active_tickets[key] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    key = normalize_plate(plate)
    ticket = key && @active_tickets[key]
    unless ticket
      return { success: false, message: 'No car found' }
    end

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(key)

    @active_tickets.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration.round(2) }
  end

  def garage_status
    available = @garage.small + @garage.medium + @garage.large
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @total_spots - available,
      total_available:  available
    }
  end

  def find_ticket(plate)
    key = normalize_plate(plate)
    key ? @active_tickets.fetch(key, nil) : nil
  end

  private

  attr_reader :garage
end