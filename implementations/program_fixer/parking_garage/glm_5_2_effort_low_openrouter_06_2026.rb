require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      'small' => [],
      'medium' => [],
      'large' => []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    return "Invalid license plate" if plate.empty?
    
    size = car_size.to_s.downcase.strip
    return "Invalid car size" unless ['small', 'medium', 'large'].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots['small'] << car
        @small -= 1
        "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots['medium'] << car
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots['large'] << car
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots['medium'] << car
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots['large'] << car
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots['large'] << car
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    spot_type = nil
    car_to_remove = nil

    @parking_spots.each do |type, cars|
      found = cars.find { |c| c[:plate] == plate }
      if found
        car_to_remove = found
        spot_type = type
        break
      end
    end

    if car_to_remove
      @parking_spots[spot_type].delete(car_to_remove)
      case spot_type
      when 'small' then @small += 1
      when 'medium' then @medium += 1
      when 'large' then @large += 1
      end
      "car with license plate no. #{plate} exited"
    else
      "Car not found"
    end
  end

  def shuffle_large(car)
    if @medium > 0
      medium_in_large = @parking_spots['large'].find { |c| c[:size] == 'medium' }
      if medium_in_large
        @parking_spots['large'].delete(medium_in_large)
        @parking_spots['medium'] << medium_in_large
        @medium -= 1
        
        @parking_spots['large'] << car
        "car with license plate no. #{car[:plate]} is parked at large"
      else
        "No space available"
      end
    else
      "No space available"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = "TK-#{SecureRandom.hex(4)}"
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
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    
    duration = duration_hours.to_f
    return 0.0 if duration <= 0.25
    return 0.0 if duration < 0

    hours = duration.ceil
    rate = RATES[size]
    total = hours * rate
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str = size.to_s.downcase.strip
    
    verdict = @garage.admit_car(plate_str, size_str)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tickets[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tickets[plate_str]
    return { success: false, message: 'No active ticket' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)

    @tickets.delete(plate_str)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @tickets.size,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s.strip]
  end
end