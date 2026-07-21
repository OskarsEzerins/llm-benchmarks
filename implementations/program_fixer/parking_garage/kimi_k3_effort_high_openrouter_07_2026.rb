require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

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
    plate = license_plate_no.to_s.strip
    size  = car_size.to_s.strip.downcase

    return parking_status if plate.empty?
    return parking_status unless VALID_SIZES.include?(size)

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
    plate = license_plate_no.to_s

    small_car  = @parking_spots[:small].detect  { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium].detect { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large].detect  { |c| c[:plate] == plate }

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
    small_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }

    if small_in_medium && @small > 0
      @parking_spots[:medium].delete(small_in_medium)
      @parking_spots[:small] << small_in_medium
      @small -= 1
      @parking_spots[:medium] << kar
      return parking_status(kar, 'medium')
    end

    parking_status
  end

  def shuffle_large(kar)
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }

    if medium_in_large && @medium > 0
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium -= 1
      @parking_spots[:large] << kar
      return parking_status(kar, 'large')
    end

    small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }

    if small_in_large && @small > 0
      @parking_spots[:large].delete(small_in_large)
      @parking_spots[:small] << small_in_large
      @small -= 1
      @parking_spots[:large] << kar
      return parking_status(kar, 'large')
    elsif small_in_large && @medium > 0
      @parking_spots[:large].delete(small_in_large)
      @parking_spots[:medium] << small_in_large
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
    if plate && !plate.to_s.strip.empty?
      "car with license plate no. #{plate} exited"
    else
      'Car not found'
    end
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

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
    duration_hours <= 24
  end

  private

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

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size     = car_size.to_s.downcase
    duration = duration_hours.to_f

    return 0.0 if duration <= GRACE_PERIOD_HOURS
    return 0.0 unless RATES.key?(size)

    billable_hours = (duration - GRACE_PERIOD_HOURS).ceil
    total = billable_hours * RATES[size]

    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  attr_reader :garage, :active_tickets

  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)

    if result.to_s.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    key    = plate.to_s
    ticket = @active_tickets[key]
    return { success: false, message: 'Car not found' } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message  = @garage.exit_car(key)

    @active_tickets.delete(key)

    { success: true, message: message, fee: fee.to_f, duration_hours: duration }
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