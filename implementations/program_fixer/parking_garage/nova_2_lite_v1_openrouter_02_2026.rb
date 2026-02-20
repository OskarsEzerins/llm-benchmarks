require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    license_plate_no = license_plate_no.to_s.strip
    car_size = car_size.to_s.downcase

    unless ['small', 'medium', 'large'].include?(car_size)
      return "Invalid car size: #{car_size}"
    end

    car = { plate: license_plate_no, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        return "car with license plate no. #{license_plate_no} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{license_plate_no} is parked at large"
      else
        return "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{license_plate_no} is parked at large"
      else
        return "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{license_plate_no} is parked at large"
      else
        return "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s.strip

    ['small', 'medium', 'large'].each do |size|
      if @parking_spots[size.to_sym].any? { |c| c[:plate] == license_plate_no }
        @parking_spots[size.to_sym].delete_if { |c| c[:plate] == license_plate_no }
        case size
        when 'small' then @small += 1
        when 'medium' then @medium += 1
        when 'large' then @large += 1
        end
        return "car with license plate no. #{license_plate_no} exited"
      end
    end

    "car with license plate no. #{license_plate_no} not found"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24
  end
end

class ParkingFeeCalculator
  RATES = {
    small: 2.0,
    medium: 3.0,
    large: 5.0
  }

  MAX_FEE = {
    small: 20.0,
    medium: 30.0,
    large: 50.0
  }

  def calculate_fee(car_size, duration_hours)
    car_size = car_size.to_s.downcase
    return 0.0 unless ['small', 'medium', 'large'].include?(car_size)
    return 0.0 if duration_hours.nil? || duration_hours < 0

    duration_hours = [duration_hours, 0].max

    grace_period = 0.25 # 15 minutes
    billable_hours = [duration_hours - grace_period, 0].max
    billable_hours = billable_hours.ceil

    rate = RATES[car_size.to_sym] || 0.0
    total = billable_hours * rate
    [total, MAX_FEE[car_size.to_sym]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)
    
    if result.start_with?('car with license plate no.')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s.strip] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate = plate.to_s.strip
    ticket = @tix_in_flight[plate]
    
    unless ticket
      return { success: false, message: "Ticket not found for plate: #{plate}" }
    end
    
    if ticket.valid?
      fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
      result = @garage.exit_car(plate)
      
      @tix_in_flight.delete(plate)
      
      { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
    else
      { success: false, message: "Ticket expired for plate: #{plate}" }
    end
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  private

  def total_occupied
    @garage.parking_spots.values.sum { |spots| spots.size }
  end

  def total_available
    @garage.small + @garage.medium + @garage.large
  end
end