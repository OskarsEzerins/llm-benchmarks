require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small_spot:  [],
      medium_spot: [],
      large_spot:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    return 'No space available' if license_plate_no.nil?

    plate = license_plate_no.to_s.strip
    return 'No space available' if plate.empty?

    size = car_size.to_s.downcase.strip
    return 'No space available' unless %w[small medium large].include?(size)

    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip

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

  def shuffle_large(kar)
    movable = @parking_spots[:large_spot].find { |c| c[:size] != 'large' }

    if movable && @medium > 0
      @parking_spots[:large_spot].delete(movable)
      @parking_spots[:medium_spot] << movable
      @medium -= 1
      @parking_spots[:large_spot] << kar
      parking_status(kar, 'large')
    else
      parking_status
    end
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
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id           = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size     = car_size.to_s.downcase
    @entry_time   = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24
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
  }

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    rate = RATES[size]
    return 0.0 if rate.nil?
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours <= GRACE_PERIOD

    billable = duration_hours - GRACE_PERIOD
    hours = billable.ceil
    total = hours * rate
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
    message = @garage.admit_car(plate, size)

    if message.to_s.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate.to_s] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    key    = plate.to_s
    ticket = @active_tickets[key]
    return { success: false, message: 'No active ticket found' } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message  = @garage.exit_car(plate)

    @active_tickets.delete(key)
    { success: true, message: message, fee: fee, duration_hours: duration }
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