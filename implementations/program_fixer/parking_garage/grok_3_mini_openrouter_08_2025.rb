require 'securerandom'
require 'time'

class ParkingGarage
  attr_reader :parking_spots, :small_available, :medium_available, :large_available

  def initialize(small, medium, large)
    @small_available = small.to_i
    @medium_available = medium.to_i
    @large_available = large.to_i
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "Invalid car size" unless ['small', 'medium', 'large'].include?(car_size.downcase)
    car_size = car_size.downcase
    car = { plate: license_plate_no.to_s.strip, size: car_size }

    case car_size
    when 'small'
      if @small_available > 0
        @parking_spots[:small] << car
        @small_available -= 1
        return "car with license plate no. #{car[:plate]} is parked at small"
      elsif @medium_available > 0
        @parking_spots[:medium] << car
        @medium_available -= 1
        return "car with license plate no. #{car[:plate]} is parked at medium"
      elsif @large_available > 0
        @parking_spots[:large] << car
        @large_available -= 1
        return "car with license plate no. #{car[:plate]} is parked at large"
      else
        return "No space available"
      end
    when 'medium'
      if @medium_available > 0
        @parking_spots[:medium] << car
        @medium_available -= 1
        return "car with license plate no. #{car[:plate]} is parked at medium"
      elsif @large_available > 0
        @parking_spots[:large] << car
        @large_available -= 1
        return "car with license plate no. #{car[:plate]} is parked at large"
      else
        return "No space available"  # Shuffling not implemented as per requirements
      end
    when 'large'
      if @large_available > 0
        @parking_spots[:large] << car
        @large_available -= 1
        return "car with license plate no. #{car[:plate]} is parked at large"
      else
        return "No space available"  # Shuffling logic can be added if specified
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s.strip
    spots = [:small, :medium, :large]
    car_to_remove = nil
    spot_type = nil

    spots.each do |spot|
      car_to_remove = @parking_spots[spot].find { |c| c[:plate] == license_plate_no }
      if car_to_remove
        spot_type = spot
        @parking_spots[spot].delete(car_to_remove)
        break
      end
    end

    if car_to_remove
      case spot_type
      when :small
        @small_available += 1
      when :medium
        @medium_available += 1
      when :large
        @large_available += 1
      end
      return "car with license plate no. #{license_plate_no} exited"
    else
      return "No car found"
    end
  end

  def garage_status
    {
      small_available: @small_available,
      medium_available: @medium_available,
      large_available: @large_available,
      total_occupied: @parking_spots[:small].size + @parking_spots[:medium].size + @parking_spots[:large].size,
      total_available: @small_available + @medium_available + @large_available
    }
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.downcase
    @entry_time = Time.now
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
    return 0.0 if duration_hours.nil? || duration_hours < 0
    car_size = car_size.downcase
    return 0.0 unless ['small', 'medium', 'large'].include?(car_size)

    billable_hours = [0, ((duration_hours - 0.25) > 0 ? ((duration_hours - 0.25).ceil) : 0)].max
    total_fee = billable_hours * RATES[car_size]
    [total_fee, MAX_FEE[car_size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid input" } if plate.nil? || plate.to_s.strip.empty? || !['small', 'medium', 'large'].include?(size.to_s.downcase)
    result = @garage.admit_car(plate, size)
    if result.start_with?("car with license plate no.")
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate = plate.to_s.strip
    ticket = @active_tickets[plate]
    return { success: false, message: "No active ticket" } unless ticket && ticket.valid?

    exit_message = @garage.exit_car(plate)
    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    @active_tickets.delete(plate)
    { success: true, message: exit_message, fee: fee, duration_hours: duration }
  end

  def garage_status
    @garage.garage_status
  end
end