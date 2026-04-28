require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

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
    license_plate_no = license_plate_no.to_s
    car_size = car_size.to_s.downcase

    car = { plate: license_plate_no, size: car_size }

    case car_size
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
        'No space available'
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
        shuffle_medium(car)
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car)
      end
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s

    small_car  = @parking_spots[:small].find  { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:large].find  { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      exit_status(license_plate_no)
    else
      "car with license plate no. #{license_plate_no} not found"
    end
  end

  def shuffle_medium(car)
    victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
    where  = :medium

    unless victim
      victim = @parking_spots[:large].find { |c| c[:size] == 'small' }
      where = :large
    end

    return 'No space available' unless victim
    return 'No space available' unless @small > 0

    @parking_spots[where].delete(victim)
    @parking_spots[:small] << victim
    @small -= 1
    @parking_spots[where] << car
    parking_status(car, where.to_s)
  end

  def shuffle_large(car)
    victim = @parking_spots[:large].find { |c| c[:size] == 'small' }

    unless victim
      victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    end

    return 'No space available' unless victim

    if victim[:size] == 'small'
      return 'No space available' unless @small > 0
      @parking_spots[:large].delete(victim)
      @parking_spots[:small] << victim
      @large += 1
      @small -= 1
    elsif victim[:size] == 'medium'
      return 'No space available' unless @medium > 0
      @parking_spots[:large].delete(victim)
      @parking_spots[:medium] << victim
      @large += 1
      @medium -= 1
    end

    @parking_spots[:large] << car
    @large -= 1
    parking_status(car, 'large')
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : 'No car found'
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate_no

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id               = SecureRandom.uuid
    @license_plate_no = license_plate.to_s
    @car_size         = car_size.to_s.downcase
    @entry_time       = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24
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

  def initialize; end

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil?

    duration_hours = duration_hours.to_f
    return 0.0 if duration_hours <= 0

    car_size = car_size.to_s.downcase

    rate    = RATES[car_size]
    max_fee = MAX_FEE[car_size]
    return 0.0 unless rate

    return 0.0 if duration_hours <= 0.25

    hours = duration_hours.ceil
    total = hours * rate
    [total, max_fee].min.to_f
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage           = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator   = ParkingFeeCalculator.new
    @active_tickets   = {}
  end

  def admit_car(plate, size)
    return { success: false, message: 'Invalid license plate', ticket: nil } unless plate && plate.to_s.strip != ''

    return { success: false, message: 'Invalid car size', ticket: nil } unless size

    size = size.to_s.downcase.strip
    return { success: false, message: 'Invalid car size', ticket: nil } unless %w[small medium large].include?(size)

    plate = plate.to_s.strip
    result = @garage.admit_car(plate, size)

    if result.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result, ticket: nil }
    end
  end

  def exit_car(plate)
    return { success: false, message: 'Invalid license plate', fee: 0.0, duration_hours: 0.0 } unless plate && plate.to_s.strip != ''

    plate = plate.to_s.strip
    ticket = @active_tickets[plate]

    duration = if ticket
      (Time.now - ticket.entry_time) / 3600.0
    else
      0.0
    end

    fee = if ticket && ticket.valid?
      @fee_calculator.calculate_fee(ticket.car_size, duration)
    else
      0.0
    end

    result = @garage.exit_car(plate)
    @active_tickets.delete(plate)

    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @active_tickets.size,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    return nil unless plate
    plate = plate.to_s.strip
    @active_tickets[plate]
  end
end