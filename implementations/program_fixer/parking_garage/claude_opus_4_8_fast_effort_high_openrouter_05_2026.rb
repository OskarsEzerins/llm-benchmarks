require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  VALID_SIZES = %w[small medium large].freeze

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
    return no_space if license_plate_no.nil?

    plate = license_plate_no.to_s.strip
    return no_space if plate.empty?

    size = car_size.to_s.downcase.strip
    return no_space unless VALID_SIZES.include?(size)

    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << kar
        @small -= 1
        parking_status(plate, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(plate, 'large')
      else
        no_space
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(plate, 'large')
      else
        no_space
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(plate, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    return 'No car found' if license_plate_no.nil?

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
      'No car found'
    end
  end

  # A large car may free up a large spot by relocating a smaller car
  # currently occupying a large spot into an appropriate smaller spot.
  def shuffle_large(kar)
    movable = @parking_spots[:large_spot].find { |c| c[:size] != 'large' }
    return no_space unless movable

    if movable[:size] == 'medium' && @medium > 0
      relocate(movable, :large_spot, :medium_spot)
      @medium -= 1
      park_large(kar)
    elsif movable[:size] == 'small' && @small > 0
      relocate(movable, :large_spot, :small_spot)
      @small -= 1
      park_large(kar)
    elsif movable[:size] == 'small' && @medium > 0
      relocate(movable, :large_spot, :medium_spot)
      @medium -= 1
      park_large(kar)
    else
      no_space
    end
  end

  private

  def park_large(kar)
    @parking_spots[:large_spot] << kar
    parking_status(kar[:plate], 'large')
  end

  def relocate(car, from, to)
    @parking_spots[from].delete(car)
    @parking_spots[to] << car
  end

  def parking_status(plate, space)
    "car with license plate no. #{plate} is parked at #{space}"
  end

  def no_space
    'No space available'
  end

  def exit_status(plate)
    "car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id           = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size     = car_size.to_s.downcase.strip
    @entry_time   = entry_time
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
    size = car_size.to_s.downcase.strip
    rate = RATES[size]
    return 0.0 unless rate

    dur = duration_hours.to_f
    return 0.0 if dur <= GRACE_PERIOD

    billable_hours = (dur - GRACE_PERIOD).ceil
    billable_hours = 0 if billable_hours.negative?

    total = billable_hours * rate
    [total.to_f, MAX_FEE[size]].min.to_f
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

    if result.to_s.include?('is parked at')
      key                  = plate.to_s.strip
      ticket               = ParkingTicket.new(key, size)
      @active_tickets[key] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    key    = plate.to_s.strip
    ticket = @active_tickets[key]
    return { success: false, message: 'No active ticket found' } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(key)

    @active_tickets.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    small  = @garage.small
    medium = @garage.medium
    large  = @garage.large

    {
      small_available:  small,
      medium_available: medium,
      large_available:  large,
      total_occupied:   @active_tickets.size,
      total_available:  small + medium + large
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end