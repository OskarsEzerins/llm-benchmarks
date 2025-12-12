require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :parking_spots

  def initialize(small, medium, large)
    @small_available  = small.to_i
    @medium_available = medium.to_i
    @large_available  = large.to_i

    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def small
    @small_available
  end

  def medium
    @medium_available
  end

  def large
    @large_available
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)
    return 'Invalid input' unless valid_plate?(plate) && size

    car = { plate: plate, size: size }

    case size
    when 'small'
      return park_in(:small, car)  if @small_available.positive?
      return park_in(:medium, car) if @medium_available.positive?
      return park_in(:large, car)  if @large_available.positive?
      'No space available'
    when 'medium'
      return park_in(:medium, car) if @medium_available.positive?
      return park_in(:large, car)  if @large_available.positive?
      shuffle_for_medium(car) || 'No space available'
    when 'large'
      return park_in(:large, car) if @large_available.positive?
      shuffle_for_large(car) || 'No space available'
    else
      'Invalid input'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Invalid input' unless valid_plate?(plate)

    [:small, :medium, :large].each do |spot|
      idx = @parking_spots[spot].index { |c| c[:plate] == plate }
      next unless idx

      @parking_spots[spot].delete_at(idx)
      increment_available(spot)
      return "car with license plate no. #{plate} exited"
    end

    'Car not found'
  end

  private

  def normalize_plate(plate)
    plate.to_s
  end

  def valid_plate?(plate)
    plate.is_a?(String) && !plate.strip.empty?
  end

  def normalize_size(size)
    s = size.to_s.strip.downcase
    return nil unless VALID_SIZES.include?(s)
    s
  end

  def park_in(spot_sym, car)
    @parking_spots[spot_sym] << car
    decrement_available(spot_sym)
    "car with license plate no. #{car[:plate]} is parked at #{spot_sym}"
  end

  def decrement_available(spot_sym)
    case spot_sym
    when :small  then @small_available  -= 1
    when :medium then @medium_available -= 1
    when :large  then @large_available  -= 1
    end
  end

  def increment_available(spot_sym)
    case spot_sym
    when :small  then @small_available  += 1
    when :medium then @medium_available += 1
    when :large  then @large_available  += 1
    end
  end

  # If medium can't fit (no medium/large available), try to move a small car
  # from medium/large into a small spot (if available), freeing a spot.
  def shuffle_for_medium(car)
    return nil unless @small_available.positive?

    # Prefer freeing a medium spot (better fit) by moving a small car out of it.
    victim_idx = @parking_spots[:medium].index { |c| c[:size] == 'small' }
    if victim_idx
      victim = @parking_spots[:medium].delete_at(victim_idx)
      increment_available(:medium)
      @parking_spots[:small] << victim
      decrement_available(:small)
      return park_in(:medium, car)
    end

    # Otherwise free a large spot by moving a small car out of it.
    victim_idx = @parking_spots[:large].index { |c| c[:size] == 'small' }
    if victim_idx
      victim = @parking_spots[:large].delete_at(victim_idx)
      increment_available(:large)
      @parking_spots[:small] << victim
      decrement_available(:small)
      return park_in(:large, car)
    end

    nil
  end

  # If large can't fit (no large available), try to move a medium car from large
  # into a medium spot (if available), freeing a large spot.
  def shuffle_for_large(car)
    return nil unless @medium_available.positive?

    victim_idx = @parking_spots[:large].index { |c| c[:size] == 'medium' }
    return nil unless victim_idx

    victim = @parking_spots[:large].delete_at(victim_idx)
    increment_available(:large)

    @parking_spots[:medium] << victim
    decrement_available(:medium)

    park_in(:large, car)
  end
end

class ParkingTicket
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = normalize_size(car_size)
    @entry_time    = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours(now_time = Time.now)
    now_t = now_time.is_a?(Time) ? now_time : Time.now
    seconds = now_t - @entry_time
    seconds = 0.0 if seconds.negative?
    seconds / 3600.0
  end

  def valid?(now_time = Time.now)
    duration_hours(now_time) < 24.0
  end

  private

  def normalize_size(size)
    s = size.to_s.strip.downcase
    VALID_SIZES.include?(s) ? s : 'small'
  end
end

class ParkingFeeCalculator
  RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }.freeze

  DAILY_MAX = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  GRACE_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    rate = RATES[size]
    return 0.0 unless rate

    dur = begin
      Float(duration_hours)
    rescue StandardError
      nil
    end
    return 0.0 if dur.nil? || dur.negative?

    return 0.0 if dur <= GRACE_HOURS

    billable = (dur - GRACE_HOURS)
    hours_to_charge = billable.ceil
    total = hours_to_charge * rate
    max_fee = DAILY_MAX[size] || total
    [total, max_fee].min.to_f
  end
end

class ParkingGarageManager
  VALID_SIZES = %w[small medium large].freeze

  def initialize(*args, small_spots: nil, medium_spots: nil, large_spots: nil)
    if args.size >= 3
      small_spots, medium_spots, large_spots = args[0], args[1], args[2]
    end

    @garage = ParkingGarage.new(small_spots.to_i, medium_spots.to_i, large_spots.to_i)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(license_plate, car_size)
    plate = normalize_plate(license_plate)
    size  = normalize_size(car_size)

    return { success: false, message: 'Invalid input', ticket: nil } unless valid_plate?(plate) && size

    verdict = @garage.admit_car(plate, size)
    if verdict.is_a?(String) && verdict.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict.to_s, ticket: nil }
    end
  end

  def exit_car(license_plate)
    plate = normalize_plate(license_plate)
    return { success: false, message: 'Invalid input', fee: 0.0, duration_hours: 0.0 } unless valid_plate?(plate)

    ticket = @tickets[plate]
    return { success: false, message: 'Ticket not found', fee: 0.0, duration_hours: 0.0 } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate)

    @tickets.delete(plate)

    { success: true, message: result, fee: fee.to_f, duration_hours: duration.to_f }
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large
    total_occupied = @tickets.size

    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   total_occupied,
      total_available:  total_available
    }
  end

  def find_ticket(license_plate)
    plate = normalize_plate(license_plate)
    @tickets[plate]
  end

  private

  def normalize_plate(plate)
    plate.to_s
  end

  def valid_plate?(plate)
    plate.is_a?(String) && !plate.strip.empty?
  end

  def normalize_size(size)
    s = size.to_s.strip.downcase
    VALID_SIZES.include?(s) ? s : nil
  end
end