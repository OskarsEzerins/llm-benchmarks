require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

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
    return "Invalid input" if license_plate_no.to_s.strip.empty? || !%w[small medium large].include?(car_size.to_s.downcase)

    plate = license_plate_no.to_s
    size = car_size.to_s.downcase

    case size
    when 'small'
      if @small > 0
        park_car(plate, size, :small)
      elsif @medium > 0
        park_car(plate, size, :medium)
      elsif @large > 0
        park_car(plate, size, :large)
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        park_car(plate, size, :medium)
      elsif @large > 0
        park_car(plate, size, :large)
      else
        "No space available"
      end
    when 'large'
      if @large > 0
        park_car(plate, size, :large)
      else
        "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    found = false
    [:small, :medium, :large].each do |type|
      car = @parking_spots[type].find { |c| c[:plate] == plate }
      if car
        @parking_spots[type].delete(car)
        instance_variable_set("@#{type}", instance_variable_get("@#{type}") + 1)
        found = true
        break
      end
    end
    found ? "car with license plate no. #{plate} exited" : "Car not found"
  end

  def status
    {
      small_available: @small,
      medium_available: @medium,
      large_available: @large,
      total_occupied: @parking_spots[:small].size + @parking_spots[:medium].size + @parking_spots[:large].size,
      total_available: @small + @medium + @large
    }
  end

  private

  def park_car(plate, size, spot_type)
    @parking_spots[spot_type] << { plate: plate, size: size }
    instance_variable_set("@#{spot_type}", instance_variable_get("@#{spot_type}") - 1)
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = Time.now
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = { 'small' => 2.0, 'medium' => 3.0, 'large' => 5.0 }
  MAX_FEE = { 'small' => 20.0, 'medium' => 30.0, 'large' => 50.0 }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours < 0
    return 0.0 if duration_hours <= 0.25 # Grace period

    hours = duration_hours.ceil
    rate = RATES[car_size.to_s.downcase] || 0.0
    total = hours * rate
    [total.to_f, MAX_FEE[car_size.to_s.downcase] || 0.0].min
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)
    if result.to_s.include?("parked")
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    ticket = @tix_in_flight[plate.to_s]
    return { success: false, message: "Ticket not found" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate)
    
    @tix_in_flight.delete(plate.to_s)
    { success: true, message: result, fee: fee.to_f, duration_hours: duration.round(2) }
  end

  def garage_status
    @garage.status
  end
end