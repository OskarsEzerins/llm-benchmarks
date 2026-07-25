require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @small_total  = @small
    @medium_total = @medium
    @large_total  = @large

    @parking_spots = {
      small_spot:  [],
      medium_spot: [],
      large_spot:  []
    }
  end

  def total_small
    @small_total
  end

  def total_medium
    @medium_total
  end

  def total_large
    @large_total
  end

  def occupied_count
    @parking_spots.values.map(&:size).reduce(0, :+)
  end

  def available_count
    @small + @medium + @large
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)

    return 'No space available' if plate.nil? || size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        park(car, :small_spot, 'small')
      elsif @medium > 0
        park(car, :medium_spot, 'medium')
      elsif @large > 0
        park(car, :large_spot, 'large')
      else
        parking_status
      end
    when 'medium'
      if @medium > 0
        park(car, :medium_spot, 'medium')
      elsif @large > 0
        park(car, :large_spot, 'large')
      else
        shuffle_medium(car)
      end
    when 'large'
      if @large > 0
        park(car, :large_spot, 'large')
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

  # A medium car needs a large spot; try to relocate a small car parked in a
  # large spot to a free small/medium spot to make room.
  def shuffle_medium(car)
    candidate = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
    return parking_status unless candidate

    if @small > 0
      @parking_spots[:large_spot].delete(candidate)
      @parking_spots[:small_spot] << candidate
      @small -= 1
      @large += 1
      park(car, :large_spot, 'large')
    elsif @medium > 0
      @parking_spots[:large_spot].delete(candidate)
      @parking_spots[:medium_spot] << candidate
      @medium -= 1
      @large += 1
      park(car, :large_spot, 'large')
    else
      parking_status
    end
  end

  # A large car needs a large spot; try to relocate a smaller car occupying a
  # large spot into an appropriate free smaller spot.
  def shuffle_large(car)
    candidate = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' && @medium > 0 }

    if candidate
      @parking_spots[:large_spot].delete(candidate)
      @parking_spots[:medium_spot] << candidate
      @medium -= 1
      @large += 1
      return park(car, :large_spot, 'large')
    end

    candidate = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
    if candidate && @small > 0
      @parking_spots[:large_spot].delete(candidate)
      @parking_spots[:small_spot] << candidate
      @small -= 1
      @large += 1
      return park(car, :large_spot, 'large')
    elsif candidate && @medium > 0
      @parking_spots[:large_spot].delete(candidate)
      @parking_spots[:medium_spot] << candidate
      @medium -= 1
      @large += 1
      return park(car, :large_spot, 'large')
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
      'car not found'
    end
  end

  private

  def park(car, spot_key, label)
    @parking_spots[spot_key] << car
    case spot_key
    when :small_spot  then @small  -= 1
    when :medium_spot then @medium -= 1
    when :large_spot  then @large  -= 1
    end
    parking_status(car, label)
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
    @license_plate = license_plate.nil? ? nil : license_plate.to_s
    @car_size      = car_size.nil? ? nil : car_size.to_s.strip.downcase
    @entry_time    = entry_time || Time.now
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end

  def to_h
    {
      id: @id,
      license_plate: @license_plate,
      car_size: @car_size,
      entry_time: @entry_time,
      duration_hours: duration_hours
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.nil? ? nil : car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    hours = begin
      Float(duration_hours)
    rescue StandardError
      return 0.0
    end

    return 0.0 if hours <= GRACE_PERIOD

    billable = (hours - GRACE_PERIOD).ceil
    billable = 1 if billable < 1

    total = billable * RATES[size]
    [total.to_f, MAX_FEE[size]].min.to_f
  end

  def hourly_rate(car_size)
    RATES[car_size.to_s.strip.downcase] || 0.0
  end

  def daily_maximum(car_size)
    MAX_FEE[car_size.to_s.strip.downcase] || 0.0
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(license_plate, car_size)
    message = @garage.admit_car(license_plate, car_size)

    if message.to_s.include?('parked')
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
    plate  = license_plate.nil? ? nil : license_plate.to_s.strip
    ticket = plate ? @active_tickets[plate] : nil

    return { success: false, message: 'car not found' } if ticket.nil?

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message  = @garage.exit_car(plate)

    if message.to_s.include?('exited')
      @active_tickets.delete(plate)
      { success: true, message: message, fee: fee, duration_hours: duration }
    else
      { success: false, message: message }
    end
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
    return nil if license_plate.nil?

    @active_tickets[license_plate.to_s.strip]
  end

  def active_tickets
    @active_tickets.values
  end
end