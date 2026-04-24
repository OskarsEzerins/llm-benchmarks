require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots
  attr_accessor :small, :medium, :large

  VALID_SIZES = %w[small medium large].freeze

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

    return 'No space available' if plate.nil? || size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status unless plate

    small_car  = @parking_spots[:small].find  { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large].find  { |c| c[:plate] == plate }

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

  private

  def normalize_plate(plate)
    return nil if plate.nil?
    s = plate.to_s.strip
    s.empty? ? nil : s
  end

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.downcase.strip
    VALID_SIZES.include?(s) ? s : nil
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
      'Car not found'
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
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
    return 0.0 if car_size.nil? || duration_hours.nil?
    size = car_size.to_s.downcase.strip
    return 0.0 unless RATES.key?(size)

    hours = duration_hours.to_f
    return 0.0 if hours <= GRACE_PERIOD
    return 0.0 if hours < 0

    billable_hours = hours.ceil
    total = billable_hours * RATES[size]
    [total.to_f, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = plate.nil? ? nil : plate.to_s.strip
    if normalized_plate.nil? || normalized_plate.empty?
      return { success: false, message: 'Invalid license plate' }
    end

    result = @garage.admit_car(normalized_plate, size)

    if result.to_s.include?('is parked at')
      ticket = ParkingTicket.new(normalized_plate, size.to_s.downcase)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    normalized_plate = plate.nil? ? nil : plate.to_s.strip
    if normalized_plate.nil? || normalized_plate.empty?
      return { success: false, message: 'Invalid license plate' }
    end

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(normalized_plate)

    @active_tickets.delete(normalized_plate)

    {
      success: true,
      message: result,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    small_avail  = @garage.small
    medium_avail = @garage.medium
    large_avail  = @garage.large
    total_avail  = small_avail + medium_avail + large_avail
    total_occ    = @active_tickets.size

    {
      small_available:  small_avail,
      medium_available: medium_avail,
      large_available:  large_avail,
      total_occupied:   total_occ,
      total_available:  total_avail
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?
    @active_tickets[plate.to_s.strip]
  end
end