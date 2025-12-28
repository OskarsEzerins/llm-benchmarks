require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    car = { plate: license_plate_no.to_s.strip, size: car_size.downcase }

    case car[:size]
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
        "No space available"
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
        shuffle_medium(car)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car)
      end

    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s.strip

    small_car = @parking_spots[:small].find { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == license_plate_no }
    large_car = @parking_spots[:large].find { |c| c[:plate] == license_plate_no }

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
      "No car with license plate #{license_plate_no} found"
    end
  end

  def shuffle_medium(car)
    if @small > 0
      victim = @parking_spots[:small].sample
      if victim
        @parking_spots[:small].delete(victim)
        @parking_spots[:medium] << victim
        @small -= 1
        @medium += 1
      end
    end

    if @medium > 0
      @parking_spots[:medium] << car
      @medium -= 1
      parking_status(car, 'medium')
    elsif @large > 0
      @parking_spots[:large] << car
      @large -= 1
      parking_status(car, 'large')
    else
      "No space available"
    end
  end

  def shuffle_large(car)
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium > 0
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @large += 1
      @medium -= 1
    end

    small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if small_in_large && @small > 0
      @parking_spots[:large].delete(small_in_large)
      @parking_spots[:small] << small_in_large
      @large += 1
      @small -= 1
    end

    if @large > 0
      @parking_spots[:large] << car
      @large -= 1
      parking_status(car, 'large')
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
      "No car found"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.downcase
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(2)
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
    car_size = car_size.to_s.downcase
    return 0.0 if duration_hours.nil? || duration_hours <= 0.25

    hours = [duration_hours - 0.25, 0].max.ceil
    rate = RATES[car_size] || 0.0
    total = hours * rate
    [total, MAX_FEE[car_size] || 0.0].min.round(2)
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets_in_flight = {}
  end

  def admit_car(license_plate, car_size)
    license_plate = license_plate.to_s.strip
    car_size = car_size.to_s.downcase

    return { success: false, message: "Invalid license plate" } if license_plate.empty?
    return { success: false, message: "Invalid car size" } unless ['small', 'medium', 'large'].include?(car_size)

    message = @garage.admit_car(license_plate, car_size)
    if message.include?("parked")
      ticket = ParkingTicket.new(license_plate, car_size)
      @tickets_in_flight[license_plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(license_plate)
    license_plate = license_plate.to_s.strip
    ticket = @tickets_in_flight[license_plate]

    return { success: false, message: "No active ticket for #{license_plate}" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(license_plate)

    @tickets_in_flight.delete(license_plate)
    { success: true, message: message, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: (@garage.parking_spots[:small].size + @garage.parking_spots[:medium].size + @garage.parking_spots[:large].size),
      total_available: (@garage.small + @garage.medium + @garage.large),
      active_tickets: @tickets_in_flight.size
    }
  end

  def find_ticket(license_plate)
    @tickets_in_flight[license_plate.to_s.strip]
  end
end