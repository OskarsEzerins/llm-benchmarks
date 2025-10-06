require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i

    @parking_spots = {
      tiny_spot:   [],
      mid_spot:    [],
      grande_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    kar = { plate: license_plate_no.to_s, size: car_size }

    case car_size.downcase
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
        parking_status
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
        parking_status
      end

    when 'large'
      if @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end
    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    plate_str = license_plate_no.to_s
    small_car = @parking_spots[:tiny_spot].find { |c| c[:plate] == plate_str }
    medium_car = @parking_spots[:mid_spot].find { |c| c[:plate] == plate_str }
    large_car = @parking_spots[:grande_spot].find { |c| c[:plate] == plate_str }

    if small_car
      @parking_spots[:tiny_spot].delete(small_car)
      @small += 1
      exit_status(plate_str)
    elsif medium_car
      @parking_spots[:mid_spot].delete(medium_car)
      @medium += 1
      exit_status(plate_str)
    elsif large_car
      @parking_spots[:grande_spot].delete(large_car)
      @large += 1
      exit_status(plate_str)
    else
      exit_status
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
      "car not found"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size = car_size.downcase
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
    "TK-#{SecureRandom.uuid}"
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

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours < 0
    
    car_size = car_size.downcase
    return 0.0 unless RATES.key?(car_size)
    
    # Grace period
    if duration_hours <= 0.25
      return 0.0
    end
    
    # Round up to next full hour
    hours = duration_hours.ceil
    
    # Calculate fee
    rate = RATES[car_size]
    total = hours * rate
    
    # Apply daily maximum
    [total, MAX_FEE[car_size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(license_plate, car_size)
    # Input validation
    return { success: false, message: "Invalid license plate" } if license_plate.nil? || license_plate.to_s.strip.empty?
    return { success: false, message: "Invalid car size" } unless ['small', 'medium', 'large'].include?(car_size.to_s.downcase)
    
    plate_str = license_plate.to_s
    size_str = car_size.to_s.downcase
    
    result = @garage.admit_car(plate_str, size_str)
    
    if result.include?("is parked at")
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(license_plate)
    plate_str = license_plate.to_s
    
    ticket = @tix_in_flight[plate_str]
    return { success: false, message: "No ticket found for this car" } unless ticket && ticket.valid?
    
    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)
    
    @tix_in_flight.delete(plate_str)
    
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: (@garage.parking_spots[:tiny_spot].size + 
                       @garage.parking_spots[:mid_spot].size + 
                       @garage.parking_spots[:grande_spot].size),
      total_available: (@garage.small + @garage.medium + @garage.large)
    }
  end

  def find_ticket(license_plate)
    @tix_in_flight[license_plate.to_s]
  end
end