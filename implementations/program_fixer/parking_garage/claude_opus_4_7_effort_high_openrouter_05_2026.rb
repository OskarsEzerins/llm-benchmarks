require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots
  attr_accessor :small, :medium, :large

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
    return parking_status if license_plate_no.nil? || car_size.nil?
    plate = license_plate_no.to_s.strip
    return parking_status if plate.empty?

    size = car_size.to_s.downcase.strip
    return parking_status unless %w[small medium large].include?(size)

    kar = { plate: plate, size: size }

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
        shuffle_medium(kar)
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

  def shuffle_medium(kar)
    large_medium = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if large_medium
      @parking_spots[:large].delete(large_medium)
      @parking_spots[:large] << kar
      if @small > 0
        @parking_spots[:small] << large_medium
        @small -= 1
      elsif @medium > 0
        @parking_spots[:medium] << large_medium
        @medium -= 1
      else
        @parking_spots[:large] << large_medium
      end
      parking_status(kar, 'large')
    else
      parking_status
    end
  end

  def shuffle_large(kar)
    relocatable = @parking_spots[:large].find { |c| c[:size] != 'large' }
    if relocatable
      target = relocatable[:size] == 'small' ? :small : :medium
      if (target == :small && @small > 0) || (target == :medium && @medium > 0)
        @parking_spots[:large].delete(relocatable)
        @parking_spots[target] << relocatable
        if target == :small
          @small -= 1
        else
          @medium -= 1
        end
        @parking_spots[:large] << kar
        return parking_status(kar, 'large')
      end
    end
    parking_status
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      "Car not found"
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
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours < 0

    size = car_size.to_s.downcase.strip
    return 0.0 unless RATES.key?(size)
    return 0.0 if duration_hours <= GRACE_PERIOD

    billable = (duration_hours - GRACE_PERIOD).ceil
    total = billable * RATES[size]
    [total.to_f, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)

    if result.to_s.include?('parked')
      key = plate.to_s
      ticket = ParkingTicket.new(key, size.to_s.downcase)
      @active_tickets[key] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    key = plate.to_s
    ticket = @active_tickets[key]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate)
    @active_tickets.delete(key)

    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    occupied = @garage.parking_spots.values.map(&:size).inject(0, :+)
    available = @garage.small + @garage.medium + @garage.large
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   occupied,
      total_available:  available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s]
  end
end