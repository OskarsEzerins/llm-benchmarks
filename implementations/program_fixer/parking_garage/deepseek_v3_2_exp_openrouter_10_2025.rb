require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

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
    return "No space available" if license_plate_no.to_s.strip.empty?
    
    car_size = car_size.to_s.downcase
    unless ['small', 'medium', 'large'].include?(car_size)
      return "No space available"
    end

    car = { plate: license_plate_no.to_s, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        "car with license plate no. #{license_plate_no} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    plate_str = license_plate_no.to_s
    small_car = @parking_spots[:small].find { |c| c[:plate] == plate_str }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate_str }
    large_car = @parking_spots[:large].find { |c| c[:plate] == plate_str }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      "car with license plate no. #{license_plate_no} exited"
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      "car with license plate no. #{license_plate_no} exited"
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      "car with license plate no. #{license_plate_no} exited"
    else
      "car with license plate no. #{license_plate_no} not found"
    end
  end

  def garage_status
    {
      small_available: @small,
      medium_available: @medium,
      large_available: @large,
      total_occupied: (@parking_spots[:small].size + @parking_spots[:medium].size + @parking_spots[:large].size),
      total_available: (@small + @medium + @large)
    }
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(2)
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.hex(4).upcase}"
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
    return 0.0 if duration_hours.nil? || duration_hours < 0
    
    car_size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(car_size)

    # Grace period: first 15 minutes free
    if duration_hours <= 0.25
      return 0.0
    end

    # Round up to next full hour
    billable_hours = duration_hours.ceil
    
    rate = RATES[car_size]
    max_fee = MAX_FEE[car_size]
    
    fee = (billable_hours * rate).round(2)
    [fee, max_fee].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets_in_flight = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid license plate" } if plate.to_s.strip.empty?
    
    size = size.to_s.downcase
    unless ['small', 'medium', 'large'].include?(size)
      return { success: false, message: "No space available" }
    end

    result = @garage.admit_car(plate, size)
    
    if result.include?("parked at")
      ticket = ParkingTicket.new(plate, size)
      @tickets_in_flight[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tickets_in_flight[plate_str]
    
    unless ticket
      return { success: false, message: "Ticket not found for #{plate}" }
    end

    unless ticket.valid?
      @tickets_in_flight.delete(plate_str)
      return { success: false, message: "Ticket expired for #{plate}" }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)
    
    @tickets_in_flight.delete(plate_str)
    
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
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

  def find_ticket(plate)
    @tickets_in_flight[plate.to_s]
  end
end