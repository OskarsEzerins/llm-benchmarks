require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small_count, medium_count, large_count)
    @small = small_count.to_i
    @medium = medium_count.to_i
    @large = large_count.to_i
    
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "No space available" if license_plate_no.nil? || license_plate_no.to_s.strip.empty?
    
    size = car_size.to_s.downcase.strip
    return "No space available" unless ['small', 'medium', 'large'].include?(size)
    
    plate = license_plate_no.to_s
    car_info = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car_info
        @small -= 1
        "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car_info
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car_info
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car_info
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car_info
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car_info
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        attempt_shuffle(car_info)
      end
    end
  end

  def exit_car(license_plate_no)
    return "car not found" if license_plate_no.nil?
    
    plate = license_plate_no.to_s
    small_car = @parking_spots[:small].find { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate }
    large_car = @parking_spots[:large].find { |c| c[:plate] == plate }

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
      "car not found"
    end
  end

  private

  def attempt_shuffle(car_info)
    return "No space available" unless @medium > 0
    
    medium_in_large_spot = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    return "No space available" unless medium_in_large_spot
    
    @parking_spots[:large].delete(medium_in_large_spot)
    @parking_spots[:medium] << medium_in_large_spot
    @medium -= 1
    @large += 1
    
    @parking_spots[:large] << car_info
    @large -= 1
    
    "car with license plate no. #{car_info[:plate]} is parked at large"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24.0
  end

  private

  def generate_ticket_id
    SecureRandom.uuid
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
    return 0.0 if duration_hours.nil?
    
    size = car_size.to_s.downcase
    duration = duration_hours.to_f
    
    return 0.0 unless RATES.key?(size)
    return 0.0 if duration <= 0.25
    
    hours = duration.ceil
    total = hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_count, medium_count, large_count)
    @garage = ParkingGarage.new(small_count, medium_count, large_count)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    if plate.nil? || plate.to_s.strip.empty?
      return { success: false, message: "No space available" }
    end
    
    unless size && ['small', 'medium', 'large'].include?(size.to_s.downcase)
      return { success: false, message: "No space available" }
    end

    result = @garage.admit_car(plate, size)
    
    if result.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    if plate.nil?
      return { success: false, message: "car not found" }
    end
    
    plate_str = plate.to_s
    ticket = @active_tickets[plate_str]
    
    unless ticket
      return { success: false, message: "car not found" }
    end
    
    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)
    
    if result.include?('exited')
      @active_tickets.delete(plate_str)
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
      total_occupied: count_occupied,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?
    @active_tickets[plate.to_s]
  end

  private

  def count_occupied
    @garage.parking_spots[:small].size + 
    @garage.parking_spots[:medium].size + 
    @garage.parking_spots[:large].size
  end
end