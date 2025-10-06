require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small_spot:  [],
      medium_spot: [],
      large_spot:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    car = { plate: license_plate_no.to_s, size: car_size.to_s.downcase }
    return "No space available" unless ['small', 'medium', 'large'].include?(car[:size])

    case car[:size]
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << car
        @small -= 1
        "car with license plate no. #{car[:plate]} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        "car with license plate no. #{car[:plate]} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        "car with license plate no. #{car[:plate]} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        "car with license plate no. #{car[:plate]} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        "car with license plate no. #{car[:plate]} is parked at large"
      else
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        "car with license plate no. #{car[:plate]} is parked at large"
      else
        "No space available"
      end
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    license_plate = license_plate_no.to_s
    
    small_car  = @parking_spots[:small_spot].detect { |c| c[:plate] == license_plate }
    medium_car = @parking_spots[:medium_spot].detect { |c| c[:plate] == license_plate }
    large_car  = @parking_spots[:large_spot].detect { |c| c[:plate] == license_plate }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      "car with license plate no. #{license_plate} exited"
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      "car with license plate no. #{license_plate} exited"
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      "car with license plate no. #{license_plate} exited"
    else
      "car with license plate no. #{license_plate} not found"
    end
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
    ((Time.now - @entry_time) / 3600).round(2)
  end

  def valid?
    duration_hours <= 24
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

  GRACE_PERIOD = 0.25 # 15 minutes in hours

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= GRACE_PERIOD
    
    car_size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(car_size)
    
    hours_to_charge = [duration_hours - GRACE_PERIOD, 0].max.ceil
    rate = RATES[car_size]
    total_fee = hours_to_charge * rate
    
    [total_fee, MAX_FEE[car_size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(license_plate, car_size)
    return { success: false, message: "Invalid car size" } unless ['small', 'medium', 'large'].include?(car_size.to_s.downcase)
    return { success: false, message: "Invalid license plate" } if license_plate.nil? || license_plate.to_s.strip.empty?
    
    result = @garage.admit_car(license_plate, car_size)

    if result.include?("parked at")
      ticket = ParkingTicket.new(license_plate, car_size)
      @active_tickets[license_plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(license_plate)
    plate = license_plate.to_s
    ticket = @active_tickets[plate]
    return { success: false, message: "No active ticket found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(license_plate)

    @active_tickets.delete(plate)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @active_tickets.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(license_plate)
    @active_tickets[license_plate.to_s]
  end
end