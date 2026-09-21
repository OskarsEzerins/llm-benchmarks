require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = non_negative_int(small)
    @medium = non_negative_int(medium)
    @large  = non_negative_int(large)
    @parking_spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)
    return 'No space available' if plate.nil? || size.nil?
    return 'No space available' if plate_parked?(plate)

    car = { plate: plate, size: size }

    case size
    when 'small'
      return park_in(car, :small)  if @small.positive?
      return park_in(car, :medium) if @medium.positive?
      return park_in(car, :large)  if @large.positive?
      'No space available'
    when 'medium'
      return park_in(car, :medium) if @medium.positive?
      return park_in(car, :large)  if @large.positive?
      shuffle_for_medium(car)
    when 'large'
      return park_in(car, :large) if @large.positive?
      shuffle_for_large(car)
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'No car found' if plate.nil?

    %i[small medium large].each do |spot|
      car = @parking_spots[spot].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot].delete(car)
      increment(spot)
      return "car with license plate no. #{plate} exited"
    end

    'No car found'
  end

  private

  def non_negative_int(value)
    number = value.to_i
    number.negative? ? 0 : number
  end

  def normalize_plate(plate)
    return nil if plate.nil?

    text = plate.to_s.strip
    text.empty? ? nil : text
  end

  def normalize_size(size)
    return nil if size.nil?

    text = size.to_s.strip.downcase
    %w[small medium large].include?(text) ? text : nil
  end

  def plate_parked?(plate)
    @parking_spots.values.any? { |cars| cars.any? { |car| car[:plate] == plate } }
  end

  def park_in(car, spot)
    @parking_spots[spot] << car
    decrement(spot)
    "car with license plate no. #{car[:plate]} is parked at #{spot}"
  end

  def move_car(car, from, to)
    @parking_spots[from].delete(car)
    @parking_spots[to] << car
    increment(from)
    decrement(to)
  end

  def decrement(spot)
    case spot
    when :small  then @small -= 1
    when :medium then @medium -= 1
    when :large  then @large -= 1
    end
  end

  def increment(spot)
    case spot
    when :small  then @small += 1
    when :medium then @medium += 1
    when :large  then @large += 1
    end
  end

  def shuffle_for_medium(car)
    if @small.positive?
      victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if victim
        move_car(victim, :medium, :small)
        return park_in(car, :medium)
      end

      victim = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if victim
        move_car(victim, :large, :small)
        return park_in(car, :large)
      end
    end

    'No space available'
  end

  def shuffle_for_large(car)
    if @medium.positive?
      victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      if victim
        move_car(victim, :large, :medium)
        return park_in(car, :large)
      end
    end

    if @small.positive?
      victim = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if victim
        move_car(victim, :large, :small)
        return park_in(car, :large)
      end
    end

    if @medium.positive?
      victim = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if victim
        move_car(victim, :large, :medium)
        return park_in(car, :large)
      end
    end

    if @small.positive?
      small_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      if small_in_medium && medium_in_large
        move_car(small_in_medium, :medium, :small)
        move_car(medium_in_large, :large, :medium)
        return park_in(car, :large)
      end

      small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_in_medium && small_in_large
        move_car(small_in_medium, :medium, :small)
        move_car(small_in_large, :large, :medium)
        return park_in(car, :large)
      end
    end

    'No space available'
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).to_f
  end

  def valid?
    duration_hours <= 24
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

  GRACE_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    duration = Float(duration_hours)
    return 0.0 if duration.negative? || duration <= GRACE_HOURS

    total = duration.ceil * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  rescue ArgumentError, TypeError
    0.0
  end
end

class ParkingGarageManager
  def initialize(*args, **kwargs)
    small = pick_count(kwargs, args, 0, :small_spots, :small)
    medium = pick_count(kwargs, args, 1, :medium_spots, :medium)
    large = pick_count(kwargs, args, 2, :large_spots, :large)

    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    message = @garage.admit_car(plate, size)
    if message.to_s.include?('is parked at')
      normalized_plate = plate.to_s.strip
      normalized_size = size.to_s.strip.downcase
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message || 'No space available' }
    end
  end

  def exit_car(plate)
    key = plate.nil? ? nil : plate.to_s.strip
    ticket = key.nil? || key.empty? ? nil : @active_tickets[key]
    return { success: false, message: 'No car found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration).to_f
    message = @garage.exit_car(key)
    @active_tickets.delete(key)

    {
      success: true,
      message: message,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    small_available = @garage.small
    medium_available = @garage.medium
    large_available = @garage.large
    total_occupied = @garage.parking_spots.values.map(&:length).inject(0, :+)

    {
      small_available: small_available,
      medium_available: medium_available,
      large_available: large_available,
      total_occupied: total_occupied,
      total_available: small_available + medium_available + large_available
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?

    key = plate.to_s.strip
    return nil if key.empty?

    @active_tickets[key]
  end

  private

  def pick_count(kwargs, args, index, *keys)
    keys.each do |key|
      return kwargs[key] if kwargs.key?(key)
    end
    args[index] || 0
  end
end