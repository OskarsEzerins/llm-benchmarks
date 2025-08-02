require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      tiny_spot:   [],
      mid_spot:    [],
      grande_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    car_size = car_size.downcase
    license_plate_no = license_plate_no.to_s.strip
    return { success: false, message: 'Invalid license plate or car size' } if license_plate_no.empty? || !['small', 'medium', 'large'].include?(car_size)

    kar = { plate: license_plate_no, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:tiny_spot] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        { success: false, message: 'No space available' }
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end

    when 'large'
      if @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s.strip
    small_car  = @parking_spots[:tiny_spot].find { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:mid_spot].find  { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:grande_spot].find { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:tiny_spot].delete(small_car)
      @small += 1
      exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:mid_spot].delete(medium_car)
      @medium += 1
      exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:grande_spot].delete(large_car)
      @large += 1
      exit_status(license_plate_no)
    else
      { success: false, message: 'Car not found' }
    end
  end

  def shuffle_medium(kar)
    victim = (@parking_spots[:mid_spot] + @parking_spots[:grande_spot]).sample
    return { success: false, message: 'No space available' } unless victim

    where = @parking_spots.key(victim) || :mid_spot
    @parking_spots[where].delete(victim)
    @parking_spots[:tiny_spot] << victim
    @small -= 1
    @parking_spots[where] << kar
    parking_status(kar, where.to_s.sub('_spot', ''))
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:grande_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:grande_spot].delete(first_medium)
      @parking_spots[:mid_spot] << first_medium
      @parking_spots[:grande_spot] << kar
      @medium -= 1
      parking_status(kar, 'large')
    else
      { success: false, message: 'No space available' }
    end
  end

  def parking_status(car = nil, space = nil)
    if car && space
      { success: true, message: "car with license plate no. #{car[:plate]} is parked at #{space}" }
    else
      { success: false, message: 'No space available' }
    end
  end

  def exit_status(plate)
    { success: true, message: "car with license plate no. #{plate} exited" }
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate
    @car_size = car_size
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - entry_time) / 3600).ceil
  end

  def valid?
    duration_hours <= 24
  end
end

class ParkingFeeCalculator
  RATES = {
    small:  2.0,
    medium: 3.0,
    large:  5.0
  }

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= GRACE_PERIOD

    hours = [duration_hours - GRACE_PERIOD, 0].max.ceil
    rate  = RATES[car_size.to_sym]
    total = hours * rate
    [total, MAX_FEE[car_size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(license_plate_no, car_size)
    result = @garage.admit_car(license_plate_no, car_size)
    if result[:success]
      ticket = ParkingTicket.new(license_plate_no, car_size)
      @tix_in_flight[license_plate_no] = ticket
      { success: true, message: result[:message], ticket: ticket }
    else
      { success: false, message: result[:message] }
    end
  end

  def exit_car(license_plate_no)
    ticket = @tix_in_flight[license_plate_no]
    return { success: false, message: 'Ticket not found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    exit_result = @garage.exit_car(license_plate_no)
    @tix_in_flight.delete(license_plate_no)
    if exit_result[:success]
      { success: true, message: exit_result[:message], fee: fee, duration_hours: ticket.duration_hours }
    else
      { success: false, message: exit_result[:message] }
    end
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @tix_in_flight.size,
      total_available: @garage.small + @garage.medium + @garage.large - @tix_in_flight.size
    }
  end
end