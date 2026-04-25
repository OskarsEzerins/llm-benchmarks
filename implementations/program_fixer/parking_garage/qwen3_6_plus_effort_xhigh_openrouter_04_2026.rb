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
    plate = license_plate_no.to_s.strip
    return "Invalid license plate" if plate.empty?

    size = car_size.to_s.strip.downcase
    return "Invalid car size" unless %w[small medium large].include?(size)

    spot_type = allocate_spot(size)
    return "No space available" unless spot_type

    @parking_spots[spot_type] << { plate: plate, size: size }
    instance_variable_set("@#{spot_type}", instance_variable_get("@#{spot_type}") - 1)
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    return "Invalid license plate" if plate.empty?

    spot = nil
    type = nil

    @parking_spots.each do |t, cars|
      car = cars.find { |c| c[:plate] == plate }
      if car
        spot = car
        type = t
        break
      end
    end

    return "Car not found" unless spot

    @parking_spots[type].delete(spot)
    instance_variable_set("@#{type}", instance_variable_get("@#{type}") + 1)
    "car with license plate no. #{plate} exited"
  end

  private

  def allocate_spot(size)
    case size
    when 'small'
      return :small if @small > 0
      return :medium if @medium > 0
      return :large if @large > 0
    when 'medium'
      return :medium if @medium > 0
      return :large if @large > 0
    when 'large'
      return :large if @large > 0
    end
    nil
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.strip.downcase
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
  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    duration = duration_hours.to_f
    return 0.0 if duration <= 0.0

    rates = { 'small' => 2.0, 'medium' => 3.0, 'large' => 5.0 }
    max_fees = { 'small' => 20.0, 'medium' => 30.0, 'large' => 50.0 }

    return 0.0 unless rates.key?(size)

    if duration <= 0.25
      return 0.0
    end

    charged_hours = duration.ceil
    fee = (charged_hours * rates[size]).to_f
    [fee, max_fees[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    if plate.nil? || plate_str.empty?
      return { success: false, message: "Invalid license plate", ticket: nil }
    end

    size_str = size.to_s.strip.downcase
    unless %w[small medium large].include?(size_str)
      return { success: false, message: "Invalid car size", ticket: nil }
    end

    message = @garage.admit_car(plate_str, size_str)

    if message.include?("parked at")
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message, ticket: nil }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tix_in_flight[plate_str]
    return { success: false, message: "Invalid or expired ticket" } unless ticket

    unless ticket.valid?
      @tix_in_flight.delete(plate_str)
      return { success: false, message: "Ticket expired" }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    message = @garage.exit_car(plate_str)
    @tix_in_flight.delete(plate_str)

    { success: true, message: message, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    small_avail = @garage.small
    medium_avail = @garage.medium
    large_avail = @garage.large
    total_occupied = @tix_in_flight.size
    total_available = small_avail + medium_avail + large_avail

    {
      small_available: small_avail,
      medium_available: medium_avail,
      large_available: large_avail,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight.fetch(plate.to_s.strip, nil)
  end
end