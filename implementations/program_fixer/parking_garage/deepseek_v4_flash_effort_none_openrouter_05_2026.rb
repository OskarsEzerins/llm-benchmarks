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
    return "No space available" if license_plate_no.nil? || car_size.nil?
    
    plate = license_plate_no.to_s.strip
    return "No space available" if plate.empty?
    
    size = car_size.to_s.downcase
    return "No space available" unless ['small', 'medium', 'large'].include?(size)
    
    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << kar
        @small -= 1
        return "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        return "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        return "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return shuffle_medium(kar, plate)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return shuffle_large(kar, plate)
      end
    end
  end

  def exit_car(license_plate_no)
    return "No car found" if license_plate_no.nil?
    
    plate = license_plate_no.to_s.strip
    return "No car found" if plate.empty?

    small_car = @parking_spots[:small_spot].find { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium_spot].find { |c| c[:plate] == plate }
    large_car = @parking_spots[:large_spot].find { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      return "car with license plate no. #{plate} exited"
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      return "car with license plate no. #{plate} exited"
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      return "car with license plate no. #{plate} exited"
    else
      return "No car found"
    end
  end

  def shuffle_medium(kar, plate)
    victim = (@parking_spots[:medium_spot] + @parking_spots[:large_spot]).find { |c| c[:size] == 'small' }
    return "No space available" unless victim

    victim_spot = @parking_spots[:medium_spot].include?(victim) ? :medium_spot : :large_spot
    @parking_spots[victim_spot].delete(victim)
    
    if @small > 0
      @parking_spots[:small_spot] << victim
      @small -= 1
    else
      @parking_spots[:medium_spot] << victim
      @medium -= 1
    end
    
    @parking_spots[:large_spot] << kar
    @large -= 1
    victim_spot == :medium_spot ? @medium += 1 : @large += 1
    
    return "car with license plate no. #{plate} is parked at large"
  end

  def shuffle_large(kar, plate)
    medium_in_large = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium > 0
      @parking_spots[:large_spot].delete(medium_in_large)
      @parking_spots[:medium_spot] << medium_in_large
      @medium -= 1
      @parking_spots[:large_spot] << kar
      return "car with license plate no. #{plate} is parked at large"
    end
    
    small_in_large = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
    if small_in_large && @small > 0
      @parking_spots[:large_spot].delete(small_in_large)
      @parking_spots[:small_spot] << small_in_large
      @small -= 1
      @parking_spots[:large_spot] << kar
      return "car with license plate no. #{plate} is parked at large"
    end
    
    return "No space available"
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
    duration_hours <= 24
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
    return 0.0 if duration_hours.nil? || duration_hours < 0
    
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 if duration_hours <= 0.25

    hours = duration_hours.ceil
    rate = RATES[size] || 0
    total = hours * rate
    
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
    return { success: false, message: "No space available", ticket: nil } if plate.nil? || size.nil?
    
    plate_str = plate.to_s.strip
    return { success: false, message: "No space available", ticket: nil } if plate_str.empty?
    
    size_str = size.to_s.downcase
    return { success: false, message: "No space available", ticket: nil } unless ['small', 'medium', 'large'].include?(size_str)

    result = @garage.admit_car(plate_str, size_str)

    if result.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result, ticket: nil }
    end
  end

  def exit_car(plate)
    return { success: false, message: "No car found", fee: 0.0, duration_hours: 0.0 } if plate.nil?
    
    plate_str = plate.to_s.strip
    return { success: false, message: "No car found", fee: 0.0, duration_hours: 0.0 } if plate_str.empty?

    ticket = @tix_in_flight[plate_str]
    return { success: false, message: "No car found", fee: 0.0, duration_hours: 0.0 } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    
    result = @garage.exit_car(plate_str)
    
    @tix_in_flight.delete(plate_str)
    
    if result.include?('exited')
      { success: true, message: result, fee: fee, duration_hours: duration }
    else
      { success: false, message: result, fee: 0.0, duration_hours: 0.0 }
    end
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @tix_in_flight.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?
    @tix_in_flight[plate.to_s.strip]
  end
end