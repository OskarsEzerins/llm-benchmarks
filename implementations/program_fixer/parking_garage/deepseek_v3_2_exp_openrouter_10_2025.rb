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
    license_plate_no = license_plate_no.to_s.strip
    car_size = car_size.to_s.downcase.strip
    
    return "Invalid license plate" if license_plate_no.empty?
    return "Invalid car size" unless ['small', 'medium', 'large'].include?(car_size)

    car = { plate: license_plate_no, size: car_size }

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
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        "No space available"
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
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(1)
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
    car_size = car_size.to_s.downcase
    return 0.0 if duration_hours.nil? || duration_hours < 0

    effective_hours = duration_hours - 0.25
    return 0.0 if effective_hours <= 0

    hours_to_charge = effective_hours.ceil
    rate = RATES[car_size] || 0.0
    max_fee = MAX_FEE[car_size] || Float::INFINITY
    
    total_fee = (hours_to_charge * rate).to_f
    [total_fee, max_fee].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets_in_flight = {}
  end

  def admit_car(plate, size)
    plate = plate.to_s.strip
    size = size.to_s.downcase.strip
    
    return { success: false, message: "Invalid license plate" } if plate.empty?
    return { success: false, message: "Invalid car size" } unless ['small', 'medium', 'large'].include?(size)

    result = @garage.admit_car(plate, size)
    
    if result.include?("parked at")
      ticket = ParkingTicket.new(plate, size)
      @tickets_in_flight[plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate = plate.to_s
    ticket = @tickets_in_flight[plate]
    
    return { success: false, message: "Ticket not found" } unless ticket
    
    result = @garage.exit_car(plate)
    
    if result.include?("exited")
      duration = ticket.duration_hours
      fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
      @tickets_in_flight.delete(plate)
      { success: true, message: result, fee: fee, duration_hours: duration }
    else
      { success: false, message: result }
    end
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: (@garage.parking_spots[:small_spot].size + 
                @garage.parking_spots[:medium_spot].size + 
                @garage.parking_spots[:large_spot].size),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tickets_in_flight[plate]
  end
end