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
    return parking_status if license_plate_no.nil?

    plate = license_plate_no.to_s
    return parking_status if plate.strip.empty?

    return parking_status if car_size.nil?

    size = car_size.to_s.downcase
    return parking_status unless %w[small medium large].include?(size)

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
    return exit_status if license_plate_no.nil?

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
      exit_status
    end
  end

  def shuffle_large(kar)
    # Try to move a medium car out of a large spot to free space
    movable = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' || c[:size] == 'small' }

    if movable
      if movable[:size] == 'medium' && @medium > 0
        @parking_spots[:large_spot].delete(movable)
        @parking_spots[:medium_spot] << movable
        @medium -= 1
        @parking_spots[:large_spot] << kar
        return parking_status(kar, 'large')
      elsif movable[:size] == 'small' && @small > 0
        @parking_spots[:large_spot].delete(movable)
        @parking_spots[:small_spot] << movable
        @small -= 1
        @parking_spots[:large_spot] << kar
        return parking_status(kar, 'large')
      elsif movable[:size] == 'small' && @medium > 0
        @parking_spots[:large_spot].delete(movable)
        @parking_spots[:medium_spot] << movable
        @medium -= 1
        @parking_spots[:large_spot] << kar
        return parking_status(kar, 'large')
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
    if plate
      "car with license plate no. #{plate} exited"
    else
      'No space available'
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

    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)

    dur = duration_hours.to_f
    return 0.0 if dur <= GRACE_PERIOD
    return 0.0 if dur < 0

    hours = dur.ceil
    rate  = RATES[size]
    total = hours * rate

    [total.to_f, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets        = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    key    = plate.to_s
    ticket = @tickets[key]
    return { success: false, message: 'No active ticket found' } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(plate)

    @tickets.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @tickets.size,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s]
  end
end