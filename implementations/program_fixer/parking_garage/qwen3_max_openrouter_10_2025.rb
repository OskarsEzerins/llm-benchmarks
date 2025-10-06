require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small_spot:   [],
      medium_spot:  [],
      large_spot:   []
    }
  end

  def admit_car(license_plate_no, car_size)
    normalized_size = car_size.to_s.downcase
    unless ['small', 'medium', 'large'].include?(normalized_size)
      return "Invalid car size"
    end

    kar = { plate: license_plate_no.to_s, size: normalized_size }

    case normalized_size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << kar
        @small -= 1
        return "car with license plate no. #{license_plate_no} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        return "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        return "car with license plate no. #{license_plate_no} is parked at large"
      else
        return "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        return "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        return "car with license plate no. #{license_plate_no} is parked at large"
      else
        return "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        return "car with license plate no. #{license_plate_no} is parked at large"
      else
        return "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    plate_str = license_plate_no.to_s
    small_car  = @parking_spots[:small_spot].detect { |c| c[:plate] == plate_str }
    medium_car = @parking_spots[:medium_spot].detect { |c| c[:plate] == plate_str }
    large_car  = @parking_spots[:large_spot].detect { |c| c[:plate] == plate_str }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      return "car with license plate no. #{license_plate_no} exited"
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      return "car with license plate no. #{license_plate_no} exited"
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      return "car with license plate no. #{license_plate_no} exited"
    else
      return "car with license plate no. #{license_plate_no} not found"
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
    normalized_size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(normalized_size)

    # Apply grace period
    if duration_hours <= 0.25
      return 0.0
    end

    # Round up partial hours to next full hour
    hours_to_charge = (duration_hours - 0.25).ceil
    hours_to_charge = 0 if hours_to_charge < 0

    rate = RATES[normalized_size]
    total = hours_to_charge * rate
    daily_max = MAX_FEE[normalized_size]

    [total, daily_max].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    if plate.nil? || plate.to_s.strip.empty?
      return { success: false, message: "Invalid license plate", ticket: nil }
    end

    normalized_size = size.to_s.downcase
    unless ['small', 'medium', 'large'].include?(normalized_size)
      return { success: false, message: "Invalid car size", ticket: nil }
    end

    result = @garage.admit_car(plate, normalized_size)
    if result.include?("parked")
      ticket = ParkingTicket.new(plate, normalized_size)
      @tix_in_flight[plate.to_s] = ticket
      return { success: true, message: result, ticket: ticket }
    else
      return { success: false, message: result, ticket: nil }
    end
  end

  def exit_car(plate)
    if plate.nil?
      return { success: false, message: "Invalid license plate", fee: 0.0, duration_hours: 0.0 }
    end

    plate_str = plate.to_s
    ticket = @tix_in_flight[plate_str]
    if !ticket
      return { success: false, message: "No active ticket found for license plate no. #{plate_str}", fee: 0.0, duration_hours: 0.0 }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate_str)
    return { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: (@garage.parking_spots[:small_spot].size + 
                      @garage.parking_spots[:medium_spot].size + 
                      @garage.parking_spots[:large_spot].size),
      total_available: (@garage.small + @garage.medium + @garage.large)
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end