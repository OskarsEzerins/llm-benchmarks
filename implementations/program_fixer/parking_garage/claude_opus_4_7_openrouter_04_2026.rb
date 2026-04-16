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
    plate_str = license_plate_no.to_s.strip
    return 'No space available' if plate_str.empty?
    return 'No space available' if car_size.nil?

    size = car_size.to_s.downcase.strip
    return 'No space available' unless %w[small medium large].include?(size)

    kar = { plate: plate_str, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    return exit_status if license_plate_no.nil?
    plate_str = license_plate_no.to_s

    small_car  = @parking_spots[:small].find  { |c| c[:plate] == plate_str }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate_str }
    large_car  = @parking_spots[:large].find  { |c| c[:plate] == plate_str }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      exit_status(plate_str)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      exit_status(plate_str)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      exit_status(plate_str)
    else
      exit_status
    end
  end

  def shuffle_large(kar)
    # Try to find a small or medium car in large spot, move to smaller spot
    small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if small_in_large && @small > 0
      @parking_spots[:large].delete(small_in_large)
      @parking_spots[:small] << small_in_large
      @small -= 1
      @parking_spots[:large] << kar
      return parking_status(kar, 'large')
    end

    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium > 0
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium -= 1
      @parking_spots[:large] << kar
      return parking_status(kar, 'large')
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
      'Car not found'
    end
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
    duration_hours <= 24.0
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
    return 0.0 if car_size.nil? || duration_hours.nil?
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours < 0

    size = car_size.to_s.downcase
    rate = RATES[size]
    return 0.0 unless rate

    return 0.0 if duration_hours <= GRACE_PERIOD

    hours = duration_hours.ceil
    total = hours * rate
    max   = MAX_FEE[size]
    [total.to_f, max.to_f].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    if plate.nil? || plate.to_s.strip.empty?
      return { success: false, message: 'No space available' }
    end
    if size.nil? || !%w[small medium large].include?(size.to_s.downcase.strip)
      return { success: false, message: 'No space available' }
    end

    plate_str = plate.to_s
    size_str  = size.to_s.downcase.strip

    verdict = @garage.admit_car(plate_str, size_str)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @active_tickets[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    return { success: false, message: 'Ticket not found' } if plate.nil?
    plate_str = plate.to_s
    ticket = @active_tickets[plate_str]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)

    @active_tickets.delete(plate_str)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    small_avail  = @garage.small
    medium_avail = @garage.medium
    large_avail  = @garage.large
    total_avail  = small_avail + medium_avail + large_avail
    {
      small_available:  small_avail,
      medium_available: medium_avail,
      large_available:  large_avail,
      total_occupied:   @active_tickets.size,
      total_available:  total_avail
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?
    @active_tickets[plate.to_s]
  end
end