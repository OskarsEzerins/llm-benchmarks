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
    return "No space available" unless license_plate_no && car_size

    car_size = car_size.to_s.downcase
    unless %w[small medium large].include?(car_size)
      return "Invalid car size"
    end

    car = { plate: license_plate_no.to_s, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << car
        @small -= 1
        "car with license plate no. #{license_plate_no} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        shuffle_medium(car)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s
    small_car = @parking_spots[:small_spot].find { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium_spot].find { |c| c[:plate] == license_plate_no }
    large_car = @parking_spots[:large_spot].find { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      "car with license plate no. #{license_plate_no} exited"
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      "car with license plate no. #{license_plate_no} exited"
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      "car with license plate no. #{license_plate_no} exited"
    else
      "Car not found"
    end
  end

  def shuffle_medium(car)
    if @large > 0
      @parking_spots[:large_spot] << car
      @large -= 1
      "car with license plate no. #{car[:plate]} is parked at large"
    else
      "No space available"
    end
  end

  def shuffle_large(car)
    medium_car = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if medium_car && @medium > 0
      @parking_spots[:large_spot].delete(medium_car)
      @parking_spots[:medium_spot] << medium_car
      @parking_spots[:large_spot] << car
      @medium -= 1
      "car with license plate no. #{car[:plate]} is parked at large"
    else
      "No space available"
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
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours <= 0.25

    car_size = car_size.to_s.downcase
    rate = RATES[car_size] || 0.0
    max_fee = MAX_FEE[car_size] || Float::INFINITY

    hours = duration_hours.ceil
    total = (hours * rate).to_f
    [total, max_fee].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid license plate" } unless plate
    return { success: false, message: "Invalid car size" } unless %w[small medium large].include?(size.to_s.downcase)

    result = @garage.admit_car(plate, size)
    if result.include?("parked")
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate = plate.to_s
    ticket = @tickets[plate]
    return { success: false, message: "Ticket not found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)
    @tickets.delete(plate)

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