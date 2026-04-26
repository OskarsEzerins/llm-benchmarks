require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small_spots, medium_spots, large_spots)
    @small = small_spots.to_i
    @medium = medium_spots.to_i
    @large = large_spots.to_i

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(plate, size)
    return "No space available" if plate.nil? || plate.to_s.strip.empty? || !['small', 'medium', 'large'].include?(size.to_s.downcase)
    
    size = size.downcase
    car = { plate: plate.to_s, size: size }

    case size
    when 'small'
      if @small > 0
        park_in(:small, car)
      elsif @medium > 0
        park_in(:medium, car)
      elsif @large > 0
        park_in(:large, car)
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        park_in(:medium, car)
      elsif @large > 0
        park_in(:large, car)
      else
        "No space available"
      end
    when 'large'
      if @large > 0
        park_in(:large, car)
      else
        "No space available"
      end
    end
  end

  def exit_car(plate)
    plate = plate.to_s
    [:small, :medium, :large].each do |type|
      car = @parking_spots[type].find { |c| c[:plate] == plate }
      if car
        @parking_spots[type].delete(car)
        instance_variable_set("@#{type}", instance_variable_get("@#{type}") + 1)
        return "car with license plate no. #{plate} exited"
      end
    end
    "No car found with license plate #{plate}"
  end

  def garage_status
    {
      small_available: @small,
      medium_available: @medium,
      large_available: @large,
      total_occupied: @parking_spots.values.flatten.size,
      total_available: @small + @medium + @large
    }
  end

  private

  def park_in(spot_type, car)
    @parking_spots[spot_type] << car
    instance_variable_set("@#{spot_type}", instance_variable_get("@#{spot_type}") - 1)
    "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    (Time.now - @entry_time) <= 86400
  end
end

class ParkingFeeCalculator
  RATES = { 'small' => 2.0, 'medium' => 3.0, 'large' => 5.0 }
  MAX_FEE = { 'small' => 20.0, 'medium' => 30.0, 'large' => 50.0 }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= 0.25
    hours = duration_hours.ceil
    fee = hours * RATES[car_size.downcase]
    [fee, MAX_FEE[car_size.downcase]].min.to_f
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
    ticket = @tix_in_flight.delete(plate.to_s)
    return { success: false, message: "Ticket not found" } unless ticket
    
    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)
    { success: true, message: result, fee: fee.round(2), duration_hours: ticket.duration_hours.round(2) }
  end

  def garage_status
    @garage.garage_status
  end
end