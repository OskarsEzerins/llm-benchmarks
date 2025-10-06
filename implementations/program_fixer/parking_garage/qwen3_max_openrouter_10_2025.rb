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
    normalized_size = normalize_car_size(car_size)
    return "Invalid car size" unless normalized_size

    kar = { plate: license_plate_no.to_s, size: normalized_size }

    case normalized_size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << kar
        @small -= 1
        return parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    plate_str = license_plate_no.to_s
    small_car  = @parking_spots[:small_spot].detect { |c| c[:plate] == plate_str }
    medium_car = @parking_spots[:medium_spot].find   { |c| c[:plate] == plate_str }
    large_car  = @parking_spots[:large_spot].find    { |c| c[:plate] == plate_str }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      return exit_status(plate_str)
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      return exit_status(plate_str)
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      return exit_status(plate_str)
    else
      return "car with license plate no. #{plate_str} not found"
    end
  end

  private

  def normalize_car_size(car_size)
    return nil if car_size.nil?
    size_str = car_size.to_s.downcase.strip
    return nil unless ['small', 'medium', 'large'].include?(size_str)
    size_str
  end

  def parking_status(car, space)
    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate)
    "car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase.strip
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
    return 0.0 if duration_hours.nil? || duration_hours <= 0

    normalized_size = car_size.to_s.downcase.strip
    return 0.0 unless RATES.key?(normalized_size)

    # Apply grace period
    if duration_hours <= 0.25
      return 0.0
    end

    # Round up partial hours
    billable_hours = (duration_hours - 0.25).ceil

    rate = RATES[normalized_size]
    total = billable_hours * rate

    max_fee = MAX_FEE[normalized_size]
    [total, max_fee].min
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    # Input validation
    plate_str = plate.to_s
    return { success: false, message: "Invalid license plate" } if plate_str.strip.empty?
    
    normalized_size = size.to_s.downcase.strip
    return { success: false, message: "Invalid car size" } unless ['small', 'medium', 'large'].include?(normalized_size)

    result = @garage.admit_car(plate_str, normalized_size)

    if result.include?("is parked at")
      ticket = ParkingTicket.new(plate_str, normalized_size)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tix_in_flight[plate_str]
    return { success: false, message: "No active ticket found for #{plate_str}" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)

    @tix_in_flight.delete(plate_str)
    { success: true, message: result, fee: fee.to_f, duration_hours: duration }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: (@garage.parking_spots[:small_spot].length + 
                      @garage.parking_spots[:medium_spot].length + 
                      @garage.parking_spots[:large_spot].length),
      total_available: (@garage.small + @garage.medium + @garage.large)
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end