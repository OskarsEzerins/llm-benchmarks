require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @small = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large = [large.to_i, 0].max
    @parking_spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)
    return no_space unless plate && size

    case size
    when 'small'
      try_park(plate, size, :small, :medium, :large)
    when 'medium'
      try_park(plate, size, :medium, :large)
    when 'large'
      park_large(plate)
    else
      no_space
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return "No car with license plate no. #{plate} found" unless plate

    @parking_spots.each do |spot, cars|
      car = cars.find { |c| c[:plate] == plate }
      if car
        cars.delete(car)
        increment(spot)
        return "car with license plate no. #{plate} exited"
      end
    end

    "No car with license plate no. #{plate} found"
  end

  def occupied_count
    @parking_spots.values.sum(&:size)
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?
    s = plate.to_s.strip
    s.empty? ? nil : s
  end

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    %w[small medium large].include?(s) ? s : nil
  end

  def no_space
    'No space available'
  end

  def try_park(plate, size, *preferences)
    preferences.each do |spot|
      if available(spot) > 0
        @parking_spots[spot] << { plate: plate, size: size }
        decrement(spot)
        return "car with license plate no. #{plate} is parked at #{spot}"
      end
    end
    no_space
  end

  def park_large(plate)
    if available(:large) > 0
      @parking_spots[:large] << { plate: plate, size: 'large' }
      decrement(:large)
      return "car with license plate no. #{plate} is parked at large"
    end

    movable = @parking_spots[:large].find do |c|
      (c[:size] == 'medium' && available(:medium) > 0) ||
      (c[:size] == 'small' && available(:small) > 0)
    end

    if movable
      @parking_spots[:large].delete(movable)
      target = movable[:size] == 'medium' ? :medium : :small
      @parking_spots[target] << movable
      decrement(target)
      @parking_spots[:large] << { plate: plate, size: 'large' }
      return "car with license plate no. #{plate} is parked at large"
    end

    no_space
  end

  def available(spot)
    case spot
    when :small then @small
    when :medium then @medium
    when :large then @large
    else 0
    end
  end

  def decrement(spot)
    case spot
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
  end

  def increment(spot)
    case spot
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s.strip
    @car_size = normalize_size(car_size)
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    %w[small medium large].include?(s) ? s : nil
  end

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
    size = normalize_size(car_size)
    return 0.0 unless size

    duration = to_duration(duration_hours)
    return 0.0 unless duration
    return 0.0 if duration <= GRACE_PERIOD

    hours = duration.ceil
    total = hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    %w[small medium large].include?(s) ? s : nil
  end

  def to_duration(value)
    return value if value.is_a?(Numeric)
    return value.to_f if value.is_a?(String) && value.strip =~ /\A-?\d+(\.\d+)?\z/
    nil
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    message = @garage.admit_car(plate, size)

    if message.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[ticket.license_plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @active_tickets[plate_str]

    unless ticket
      return { success: false, message: "No active ticket for license plate no. #{plate_str}" }
    end

    message = @garage.exit_car(plate_str)
    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    @active_tickets.delete(plate_str)

    { success: true, message: message, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large
    occupied = @garage.occupied_count

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end