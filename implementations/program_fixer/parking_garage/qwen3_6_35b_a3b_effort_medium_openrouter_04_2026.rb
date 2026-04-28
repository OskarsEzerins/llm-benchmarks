require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :spots

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase

    return "No space available" if plate.empty? || !['small', 'medium', 'large'].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @spots[:small] << car; @small -= 1
        "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @spots[:medium] << car; @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @spots[:large] << car; @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        @spots[:medium] << car; @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @spots[:large] << car; @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    when 'large'
      if @large > 0
        @spots[:large] << car; @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    
    [:small, :medium, :large].each do |spot_type|
      car = @spots[spot_type].find { |c| c[:plate] == plate }
      if car
        @spots[spot_type].delete(car)
        instance_variable_set("@#{spot_type}", instance_variable_get("@#{spot_type}") + 1)
        return "car with license plate no. #{plate} exited"
      end
    end
    "Car not found"
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
    (Time.now - entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = { small: 2.0, medium: 3.0, large: 5.0 }
  MAX_FEE = { small: 20.0, medium: 30.0, large: 50.0 }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || duration_hours < 0
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size.to_sym)
    return 0.0 if duration_hours <= 0.25

    hours = duration_hours.ceil
    rate = RATES[size.to_sym]
    max = MAX_FEE[size.to_sym]
    [hours * rate, max].min
  end
end

class ParkingGarageManager
  def initialize(small_spots = 0, medium_spots = 0, large_spots = 0)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str = size.to_s.downcase
    
    if plate_str.empty? || !['small', 'medium', 'large'].include?(size_str)
      return { success: false, message: "No space available", ticket: nil }
    end

    message = @garage.admit_car(plate_str, size_str)

    if message.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tickets[plate_str] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message, ticket: nil }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tickets[plate_str]
    return { success: false, message: "Car not found", fee: 0.0, duration_hours: 0.0 } unless ticket

    unless ticket.valid?
      @garage.exit_car(plate_str)
      @tickets.delete(plate_str)
      return { success: false, message: "Ticket expired", fee: 0.0, duration_hours: ticket.duration_hours }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    message = @garage.exit_car(plate_str)
    @tickets.delete(plate_str)
    
    { success: true, message: message, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    occupied = @tickets.size
    available = @garage.small + @garage.medium + @garage.large
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: occupied,
      total_available: available
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s]
  end
end