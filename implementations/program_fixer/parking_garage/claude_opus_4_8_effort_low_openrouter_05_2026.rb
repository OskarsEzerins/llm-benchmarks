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
    return 'No space available' if license_plate_no.nil?

    plate = license_plate_no.to_s.strip
    return 'No space available' if plate.empty?
    return 'No space available' if car_size.nil?

    size = car_size.to_s.downcase.strip
    return 'No space available' unless %w[small medium large].include?(size)

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
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    return exit_status if license_plate_no.nil?

    plate = license_plate_no.to_s

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

  def shuffle_large(car)
    # Try to relocate a smaller car currently occupying a large spot
    movable = @parking_spots[:large].find { |c| c[:size] != 'large' }

    if movable
      if movable[:size] == 'small' && @small > 0
        @parking_spots[:large].delete(movable)
        @parking_spots[:small] << movable
        @small -= 1
        @parking_spots[:large] << car
        @large -= 1
        @large += 1 # spot freed then taken again -> net zero; kept explicit
        @large = @large # no-op clarity
        return parking_status(car, 'large')
      elsif %w[small medium].include?(movable[:size]) && @medium > 0
        @parking_spots[:large].delete(movable)
        @parking_spots[:medium] << movable
        @medium -= 1
        @parking_spots[:large] << car
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
    plate ? "car with license plate no. #{plate} exited" : 'No space available'
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if car_size.nil? || duration_hours.nil?
    return 0.0 unless duration_hours.is_a?(Numeric)

    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 if duration_hours <= GRACE_PERIOD

    hours = duration_hours.ceil
    rate  = RATES[size]
    total = hours * rate

    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)

    if result.to_s.include?('parked')
      key    = plate.to_s
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[key] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    key    = plate.to_s
    ticket = @active_tickets[key]
    return { success: false, message: 'No active ticket found' } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(plate)

    @active_tickets.delete(key)
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
    @active_tickets[plate.to_s]
  end
end