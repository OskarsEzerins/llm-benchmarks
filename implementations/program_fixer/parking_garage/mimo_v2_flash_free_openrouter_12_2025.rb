require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

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
    return "No space available" if license_plate_no.nil? || license_plate_no.to_s.strip.empty?
    
    plate = license_plate_no.to_s
    size = case car_size.to_s.downcase.strip
           when 'small', 's' then 'small'
           when 'medium', 'm' then 'medium'
           when 'large', 'l' then 'large'
           else nil
           end
    
    return "No space available" if size.nil?

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << { plate: plate, size: 'small' }
        @small -= 1
        "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << { plate: plate, size: 'small' }
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << { plate: plate, size: 'small' }
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << { plate: plate, size: 'medium' }
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << { plate: plate, size: 'medium' }
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        shuffle_medium({ plate: plate, size: 'medium' })
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << { plate: plate, size: 'large' }
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        shuffle_large({ plate: plate, size: 'large' })
      end
    end
  end

  def exit_car(license_plate_no)
    return "No space available" if license_plate_no.nil?
    
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
      "No space available"
    end
  end

  private

  def shuffle_medium(kar)
    if @large > 0
      @parking_spots[:large] << kar
      @large -= 1
      "car with license plate no. #{kar[:plate]} is parked at large"
    else
      "No space available"
    end
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large].delete(first_medium)
      @parking_spots[:medium] << first_medium
      @medium -= 1
      @large += 1
      
      @parking_spots[:large] << kar
      @large -= 1
      "car with license plate no. #{kar[:plate]} is parked at large"
    elsif @large > 0
      @parking_spots[:large] << kar
      @large -= 1
      "car with license plate no. #{kar[:plate]} is parked at large"
    else
      "No space available"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase.strip
    @entry_time    = entry_time
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
    return 0.0 if duration_hours.nil? || duration_hours < 0
    
    size = car_size.to_s.downcase.strip
    return 0.0 unless ['small', 'medium', 'large'].include?(size)
    
    grace_period = 0.25
    adjusted_hours = [duration_hours - grace_period, 0].max
    
    return 0.0 if adjusted_hours == 0
    
    hours_to_bill = adjusted_hours.ceil
    rate = RATES[size]
    total = hours_to_bill * rate
    
    [total, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)
    
    if verdict && verdict.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict || "No space available" }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tix_in_flight[plate_str]
    return { success: false, message: "Car not found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)
    
    @tix_in_flight.delete(plate_str)
    
    if result.include?('exited')
      { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
    else
      { success: false, message: result }
    end
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: calculate_occupied,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tix_in_flight.fetch(plate.to_s, nil)
  end

  private

  def calculate_occupied
    total_spots = @garage.small + @garage.medium + @garage.large
    total_available = @garage.small + @garage.medium + @garage.large
    total_spots - total_available
  end
end