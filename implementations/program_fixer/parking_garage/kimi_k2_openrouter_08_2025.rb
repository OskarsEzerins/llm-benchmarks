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
    return "Invalid car size" unless %w[small medium large].include?(car_size.to_s.downcase)
    
    plate = license_plate_no.to_s.strip
    return "Invalid license plate" if plate.empty?
    
    car_size = car_size.to_s.downcase
    kar = { plate: plate, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
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
    ((Time.now - @entry_time) / 3600.0).round(2)
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
    return 0.0 if duration_hours < 0
    return 0.0 if duration_hours <= 0.25
    
    car_size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(car_size)
    
    hours = duration_hours.ceil
    total = hours * RATES[car_size]
    [total, MAX_FEE[car_size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid input" } if plate.nil? || size.nil?
    
    verdict = @garage.admit_car(plate, size)
    
    if verdict.include?("parked")
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    ticket = @tix_in_flight[plate.to_s]
    return { success: false, message: "No active ticket found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)
    
    @tix_in_flight.delete(plate.to_s)
    { success: true, message: result, fee: fee.to_f, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: (@garage.parking_spots.values.map(&:size).sum),
      total_available: (@garage.small + @garage.medium + @garage.large),
      active_tickets: @tix_in_flight.size
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end