require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i

    @parking_spots = {
      tiny_spot: [],
      mid_spot: [],
      grande_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return { success: false, message: "Invalid license plate" } if license_plate_no.nil? || license_plate_no.strip.empty?
    car_size = car_size.downcase
    return { success: false, message: "Invalid car size" } unless ['small', 'medium', 'large'].include?(car_size)

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
        { success: false, message: "No space available" }
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
    return "No such car" if license_plate_no.nil? || license_plate_no.strip.empty?
    
    small_car  = @parking_spots[:tiny_spot].detect { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:mid_spot].find   { |c| c[:plate] == license_plate_no }
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
      exit_status
    end
  end

  def shuffle_medium(kar)
    victim = (@parking_spots[:mid_spot] + @parking_spots[:grande_spot]).sample
    return parking_status unless victim

    where = @parking_spots.key(victim) || :mid_spot
    @parking_spots[where].delete(victim)
    @parking_spots[:tiny_spot] << victim
    @small -= 1
    @parking_spots[where] << kar
    parking_status(kar, where.to_s.sub('_spot', ''))
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:mid_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:mid_spot].delete(first_medium)
      @parking_spots[:grande_spot] << first_medium
      @parking_spots[:grande_spot] << kar
      @medium -= 1
      parking_status(kar, 'large')
    end
    parking_status
  end

  def parking_status(car = nil, space = nil)
    if car && space
      puts "🚗  #{car[:plate]} parked @ #{space}"
    else
      puts '¯\_(ツ)_/¯'
    end
  end

  def exit_status(plate = nil)
    plate ? puts("👋 #{plate} left") : puts('Ghost car?')
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license = license_plate.to_s
    @car_size = car_size.downcase
    @entry_time = entry_time
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
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return -1 if duration_hours < 0
    hours = duration_hours > 0.25 ? duration_hours.ceil : 0
    rate = RATES[car_size.downcase] || 0
    total = hours * rate
    [total, MAX_FEE[car_size.downcase] || Float::INFINITY].min
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)

    if verdict.is_a?(Hash) && verdict[:success]
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate] = ticket
      { success: true, message: verdict[:message], ticket: ticket }
    else
      { success: false, message: verdict[:message] }
    end
  end

  def exit_car(plate)
    ticket = @tix_in_flight[plate]
    return { success: false, message: 'No such ticket' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: (@garage.small + @garage.medium + @garage.large) - (@garage.small + @garage.medium + @garage.large),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end
end