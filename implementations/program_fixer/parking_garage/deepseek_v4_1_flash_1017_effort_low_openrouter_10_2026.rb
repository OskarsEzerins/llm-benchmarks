require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large = [large.to_i, 0].max
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)
    return "No space available" unless plate && size
    return "car with license plate no. #{plate} is already parked" if parked_anywhere?(plate)

    spot = first_available_spot(size)
    unless spot
      if attempt_shuffle_for(size)
        spot = first_available_spot(size)
      end
    end

    if spot
      park_at(plate, size, spot)
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return "No car found" unless plate

    @parking_spots.each do |spot, cars|
      car = cars.find { |c| c[:plate] == plate }
      if car
        cars.delete(car)
        increment_available(spot)
        return "car with license plate no. #{plate} exited"
      end
    end

    "car with license plate no. #{plate} not found"
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?
    str = plate.to_s.strip
    return nil if str.empty?
    str
  end

  def normalize_size(size)
    str = size.to_s.strip.downcase
    %w[small medium large].include?(str) ? str : nil
  end

  def parked_anywhere?(plate)
    @parking_spots.values.any? { |cars| cars.any? { |c| c[:plate] == plate } }
  end

  def acceptable_spots_for(size)
    case size
    when 'small' then [:small, :medium, :large]
    when 'medium' then [:medium, :large]
    when 'large' then [:large]
    else []
    end
  end

  def first_available_spot(size)
    acceptable_spots_for(size).find { |spot| available_count(spot) > 0 }
  end

  def available_count(spot)
    case spot
    when :small then @small
    when :medium then @medium
    when :large then @large
    else 0
    end
  end

  def decrement_available(spot)
    case spot
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
  end

  def increment_available(spot)
    case spot
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end
  end

  def park_at(plate, size, spot)
    @parking_spots[spot] << { plate: plate, size: size }
    decrement_available(spot)
    "car with license plate no. #{plate} is parked at #{spot}"
  end

  def attempt_shuffle_for(size)
    acceptable_spots_for(size).each do |target_spot|
      @parking_spots[target_spot].dup.each do |car|
        return true if try_move_car_out(car, target_spot, [target_spot])
      end
    end
    false
  end

  def try_move_car_out(car, from_spot, forbidden)
    destinations = acceptable_spots_for(car[:size]) - [from_spot] - forbidden

    destinations.each do |dest|
      if available_count(dest) > 0
        move_car(car, from_spot, dest)
        return true
      end
    end

    destinations.each do |dest|
      @parking_spots[dest].dup.each do |other|
        next if other.equal?(car)
        if try_move_car_out(other, dest, forbidden + [dest])
          move_car(car, from_spot, dest)
          return true
        end
      end
    end

    false
  end

  def move_car(car, from_spot, to_spot)
    @parking_spots[from_spot].delete(car)
    @parking_spots[to_spot] << car
    increment_available(from_spot)
    decrement_available(to_spot)
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(3)
  end

  def valid?
    ((Time.now - @entry_time) / 3600.0) < 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
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

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    duration = begin
      Float(duration_hours)
    rescue ArgumentError, TypeError
      return 0.0
    end

    return 0.0 if duration <= 0.25

    hours = duration.ceil
    total = hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **options)
    if small_spots.is_a?(Hash)
      opts = small_spots
      small_spots = opts[:small_spots] || opts[:small] || 0
      medium_spots = opts[:medium_spots] || opts[:medium] || 0
      large_spots = opts[:large_spots] || opts[:large] || 0
    elsif options.any?
      small_spots = options[:small_spots] || options[:small] || small_spots || 0
      medium_spots = options[:medium_spots] || options[:medium] || medium_spots || 0
      large_spots = options[:large_spots] || options[:large] || large_spots || 0
    end

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    plate_str = normalize_plate(plate)
    size_str = normalize_size(size)

    if plate_str && @tickets.key?(plate_str)
      return { success: false, message: "car with license plate no. #{plate_str} is already parked" }
    end

    result = @garage.admit_car(plate, size)

    if result.include?('is parked at')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tickets[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = normalize_plate(plate)
    return { success: false, message: 'No active ticket' } unless plate_str

    ticket = @tickets[plate_str]
    return { success: false, message: "No active ticket for car with license plate no. #{plate_str}" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)

    if result.include?('exited')
      @tickets.delete(plate_str)
      { success: true, message: result, fee: fee, duration_hours: duration }
    else
      { success: false, message: result }
    end
  end

  def garage_status
    small_available = @garage.small
    medium_available = @garage.medium
    large_available = @garage.large
    total_available = small_available + medium_available + large_available
    total_occupied = @garage.parking_spots.values.map(&:length).sum

    {
      small_available: small_available,
      medium_available: medium_available,
      large_available: large_available,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    plate_str = normalize_plate(plate)
    return nil unless plate_str
    @tickets[plate_str]
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?
    str = plate.to_s.strip
    return nil if str.empty?
    str
  end

  def normalize_size(size)
    str = size.to_s.strip.downcase
    %w[small medium large].include?(str) ? str : nil
  end
end