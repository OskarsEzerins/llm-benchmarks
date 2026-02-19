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
    car = { plate: license_plate_no.to_s, size: car_size.to_s.downcase }

    case car_size.to_s.downcase
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
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    
    small_car  = @parking_spots[:small].find { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large].find { |c| c[:plate] == plate }

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
      "No car found with license plate no. #{license_plate_no}"
    end
  end

  def parking_spots
    @parking_spots
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def license_plate
    @license_plate
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
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= 0
    return 0.0 if duration_hours <= GRACE_PERIOD_HOURS
    
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    
    billable_hours = (duration_hours - GRACE_PERIOD_HOURS).ceil
    billable_hours = 1 if billable_hours < 1
    
    rate = RATES[size]
    total = billable_hours * rate
    
    [total, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets_in_flight = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid car size" } unless valid_size?(size)
    return { success: false, message: "License plate cannot be empty" } if plate.to_s.strip.empty?
    
    result = @garage.admit_car(plate, size)

    if result.to_s.include?("parked at")
      ticket = ParkingTicket.new(plate, size)
      @tickets_in_flight[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    ticket = @tickets_in_flight[plate.to_s]
    return { success: false, message: "No active ticket found for license plate #{plate}" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tickets_in_flight.delete(plate.to_s)
    { 
      success: true, 
      message: result, 
      fee: fee, 
      duration_hours: ticket.duration_hours 
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: (@garage.small + @garage.medium + @garage.large - (@garage.small + @garage.medium + @garage.large)),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tickets_in_flight[plate.to_s]
  end

  private

  def valid_size?(size)
    return false if size.nil?
    size.to_s.downcase =~ /\A(small|medium|large)\z/
  end
end