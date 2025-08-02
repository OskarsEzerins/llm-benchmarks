require 'securerandom'
require 'time'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    license_plate_no = license_plate_no.to_s.strip
    car_size = car_size.to_s.downcase

    return "No space available" unless ['small', 'medium', 'large'].include?(car_size)

    kar = { plate: license_plate_no, size: car_size }

    case car_size
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
        "No space available"
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
    license_plate_no = license_plate_no.to_s.strip

    small_car  = @parking_spots[:small].detect { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:large].find { |c| c[:plate] == license_plate_no }

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

  def shuffle_medium(kar)
    victim = (@parking_spots[:medium] + @parking_spots[:large]).sample
    return "No space available" unless victim

    where = victim[:size] == 'medium' ? :medium : :large
    @parking_spots[where].delete(victim)
    @parking_spots[:small] << victim
    @small -= 1
    @parking_spots[:medium] << kar
    @medium -= 1
    parking_status(kar, 'medium')
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large].delete(first_medium)
      @parking_spots[:medium] << first_medium
      @parking_spots[:large] << kar
      @large -= 1
      parking_status(kar, 'large')
    else
      "No space available"
    end
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
      "Ghost car?"
    end
  end

  def garage_status
    {
      small_available: @small,
      medium_available: @medium,
      large_available: @large,
      total_occupied: @parking_spots[:small].size + @parking_spots[:medium].size + @parking_spots[:large].size,
      total_available: @small + @medium + @large
    }
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600).round(2)
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
    small:  20.0,
    medium: 30.0,
    large:  50.0
  }

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0 if duration_hours <= GRACE_PERIOD

    hours = (duration_hours - GRACE_PERIOD).ceil
    rate  = RATES[car_size.to_sym] || 0
    total = hours * rate
    [total, MAX_FEE[car_size.to_sym] || 0].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)

    if verdict.include?('parked')
      ticket               = ParkingTicket.new(plate, size)
      @tix_in_flight[plate] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    ticket = @tix_in_flight[plate]
    return { success: false, message: 'nope' } unless ticket

    duration_hours = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate)
    { success: true, message: result, fee: fee, duration_hours: duration_hours }
  end

  def garage_status
    @garage.garage_status
  end

  def find_ticket(plate)
    @tix_in_flight[plate]
  end
end