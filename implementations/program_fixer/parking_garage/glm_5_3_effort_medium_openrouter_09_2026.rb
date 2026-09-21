require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  VALID_SIZES = ['small', 'medium', 'large'].freeze
  SPOT_KEYS = { 'small' => :small_spot, 'medium' => :medium_spot, 'large' => :large_spot }.freeze

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s
    size = normalize_size(car_size)
    return "No space available" if plate.nil? || plate.strip.empty?
    return "No space available" if size.nil?

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
        "No space available"
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
        "No space available"
      end
    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s

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
      "No space available"
    end
  end

  def total_occupied
    @parking_spots.values.map(&:size).sum
  end

  def total_available
    @small + @medium + @large
  end

  private

  def normalize_size(car_size)
    return nil if car_size.nil?
    size = car_size.to_s.downcase
    VALID_SIZES.include?(size) ? size : nil
  end

  def shuffle_large(car)
    displaced = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if displaced && @medium > 0
      @parking_spots[:large_spot].delete(displaced)
      @parking_spots[:medium_spot] << displaced
      @medium -= 1
      @parking_spots[:large_spot] << car
      parking_status(car, 'large')
    else
      "No space available"
    end
  end

  def parking_status(car, space)
    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate)
    "car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }

  DAILY_MAX = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    rate = RATES[size]
    max_fee = DAILY_MAX[size]
    return 0.0 if rate.nil? || max_fee.nil?

    duration = duration_hours.to_f
    return 0.0 if duration.nan? || duration <= GRACE_PERIOD_HOURS || duration < 0

    hours = duration.ceil
    total = hours * rate
    [total, max_fee].min.to_f
  end
end

class ParkingGarageManager
  VALID_SIZES = ['small', 'medium', 'large'].freeze

  def initialize(small_spots = 0, medium_spots = 0, large_spots = 0)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(license_plate, car_size)
    plate = license_plate.to_s
    size = car_size.nil? ? nil : car_size.to_s.downcase

    return { success: false, message: "Invalid license plate" } if plate.strip.empty?
    return { success: false, message: "Invalid car size" } if size.nil? || !VALID_SIZES.include?(size)

    result = @garage.admit_car(plate, size)

    if result.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(license_plate)
    plate = license_plate.to_s
    ticket = @active_tickets[plate]
    return { success: false, message: "No active ticket found for #{plate}" } if ticket.nil?

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate)

    if ticket.valid?
      @active_tickets.delete(plate)
      { success: true, message: result, fee: fee, duration_hours: duration }
    else
      @active_tickets.delete(plate)
      { success: true, message: result, fee: fee, duration_hours: duration }
    end
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.total_occupied,
      total_available: @garage.total_available
    }
  end

  def find_ticket(license_plate)
    @active_tickets[license_plate.to_s]
  end

  private

  def garage
    @garage
  end
end