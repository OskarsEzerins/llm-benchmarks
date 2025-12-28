require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase.strip

    return "No space available" if plate.empty?
    return "No space available" unless ['small', 'medium', 'large'].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << car
        @small -= 1
        return "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        return "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        return "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    return "Ghost car?" if plate.empty?

    small_car = @parking_spots[:small_spot].find { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium_spot].find { |c| c[:plate] == plate }
    large_car = @parking_spots[:large_spot].find { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      return "car with license plate no. #{plate} exited"
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      return "car with license plate no. #{plate} exited"
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      return "car with license plate no. #{plate} exited"
    else
      return "Ghost car?"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
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
    return 0.0 if duration_hours <= 0.25

    size = car_size.to_s.downcase
    rate = RATES[size] || 0.0
    max_fee = MAX_FEE[size] || Float::INFINITY

    hours = duration_hours.ceil
    fee = hours * rate
    [fee, max_fee].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str = size.to_s.downcase.strip

    return { success: false, message: "Invalid license plate" } if plate_str.empty?
    return { success: false, message: "Invalid car size" } unless ['small', 'medium', 'large'].include?(size_str)

    result = @garage.admit_car(plate_str, size_str)

    if result.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tickets[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tickets[plate_str]

    return { success: false, message: "Ticket not found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)

    @tickets.delete(plate_str)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: (@garage.parking_spots.values.flatten.size),
      total_available: (@garage.small + @garage.medium + @garage.large)
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s]
  end
end