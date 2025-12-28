require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

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
    return "No space available" unless license_plate_no && !license_plate_no.to_s.strip.empty?
    
    size = car_size.to_s.downcase.strip
    return "No space available" unless ['small', 'medium', 'large'].include?(size)
    
    plate = license_plate_no.to_s
    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    small_car  = @parking_spots[:small].find  { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large].find  { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      "car with license plate no. #{plate} exited"
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      "car with license plate no. #{plate} exited"
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      "car with license plate no. #{plate} exited"
    else
      nil
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
  attr_reader :id, :license_plate, :car_size, :entry_time

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
    return 0.0 unless duration_hours.is_a?(Numeric) && duration_hours >= 0
    
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    
    return 0.0 if duration_hours <= GRACE_PERIOD
    
    hours = duration_hours.ceil
    rate = RATES[size]
    max_fee = MAX_FEE[size]
    
    total = hours * rate
    [total, max_fee].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets        = {}
  end

  def admit_car(license_plate, car_size)
    result = @garage.admit_car(license_plate, car_size)

    if result && result.include?('parked')
      ticket = ParkingTicket.new(license_plate, car_size)
      @tickets[license_plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result || "No space available" }
    end
  end

  def exit_car(license_plate)
    plate = license_plate.to_s
    ticket = @tickets[plate]
    return { success: false, message: "Ticket not found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)
    
    @tickets.delete(plate)
    
    if result
      { success: true, message: result, fee: fee.to_f, duration_hours: ticket.duration_hours }
    else
      { success: false, message: "Car not found" }
    end
  end

  def garage_status
    status = @garage.garage_status
    {
      small_available: status[:small_available],
      medium_available: status[:medium_available],
      large_available: status[:large_available],
      total_occupied: status[:total_occupied],
      total_available: status[:total_available]
    }
  end

  def find_ticket(license_plate)
    @tickets[license_plate.to_s]
  end
end