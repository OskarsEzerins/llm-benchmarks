require 'securerandom'

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
    car = { plate: license_plate_no.to_s, size: car_size.to_s.downcase }

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
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        "No space available"
      end
    else
      "Invalid car size"
    end
  end

  def exit_car(license_plate_no)
    plate_str = license_plate_no.to_s
    small_car  = @parking_spots[:small].find { |c| c[:plate] == plate_str }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate_str }
    large_car  = @parking_spots[:large].find { |c| c[:plate] == plate_str }

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
      "Car not found"
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
    plate ? "car with license plate no. #{plate} exited" : "Car not found"
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

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

  private

  def generate_ticket_id
    "TK-#{rand(9999)}"
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
    return 0.0 if duration_hours <= 0.25  # Grace period: first 15 minutes free
    
    car_size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(car_size)
    
    hours = [duration_hours - 0.25, 0].max.ceil  # Subtract grace period and round up
    rate = RATES[car_size]
    total = hours * rate
    
    [total, MAX_FEE[car_size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(license_plate, car_size)
    # Input validation
    return { success: false, message: "Invalid license plate" } if license_plate.nil? || license_plate.to_s.strip.empty?
    return { success: false, message: "Invalid car size" } unless %w[small medium large].include?(car_size.to_s.downcase)
    
    result = @garage.admit_car(license_plate, car_size)

    if result.include?("parked")
      ticket = ParkingTicket.new(license_plate, car_size)
      @active_tickets[license_plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(license_plate)
    plate_str = license_plate.to_s
    ticket = @active_tickets[plate_str]
    return { success: false, message: "No active ticket found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(license_plate)

    @active_tickets.delete(plate_str)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.parking_spots[:small].size + 
                     @garage.parking_spots[:medium].size + 
                     @garage.parking_spots[:large].size,
      total_available: @garage.small + @garage.medium + @garage.large,
      active_tickets: @active_tickets.size
    }
  end

  def find_ticket(license_plate)
    @active_tickets[license_plate.to_s]
  end
end