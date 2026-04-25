require 'securerandom'

class ParkingGarage
  attr_reader :available_small, :available_medium, :available_large

  def initialize(small, medium, large)
    @available_small = small.to_i
    @available_medium = medium.to_i
    @available_large = large.to_i
    @parked_cars = {}
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    return "No space available" if plate.empty?

    size = car_size.to_s.strip.downcase
    return "No space available" unless %w[small medium large].include?(size)

    spot = find_spot(size)
    return "No space available" unless spot

    @parked_cars[plate] = spot
    update_count(spot, -1)
    "car with license plate no. #{plate} is parked at #{spot}"
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    spot = @parked_cars.delete(plate)
    return "No space available" unless spot

    update_count(spot, 1)
    "car with license plate no. #{plate} exited"
  end

  private

  def find_spot(size)
    case size
    when 'small'
      return 'small' if @available_small > 0
      return 'medium' if @available_medium > 0
      return 'large' if @available_large > 0
    when 'medium'
      return 'medium' if @available_medium > 0
      return 'large' if @available_large > 0
    when 'large'
      return 'large' if @available_large > 0
    end
    nil
  end

  def update_count(spot, delta)
    instance_variable_set("@available_#{spot}", instance_variable_get("@available_#{spot}") + delta)
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

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
    duration_hours < 24
  end
end

class ParkingFeeCalculator
  RATES = { 'small' => 2.0, 'medium' => 3.0, 'large' => 5.0 }.freeze
  MAX_FEE = { 'small' => 20.0, 'medium' => 30.0, 'large' => 50.0 }.freeze

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    hours = duration_hours.to_f
    size = 'small' unless RATES.key?(size)
    hours = 0.0 if hours.negative?

    return 0.0 if hours <= 0.25

    billable_hours = (hours - 0.25).ceil
    fee = billable_hours * RATES[size]
    [fee, MAX_FEE[size] || 999.0].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
    @total_spots = small.to_i + medium.to_i + large.to_i
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)
    if result == "No space available"
      { success: false, message: result }
    else
      ticket = ParkingTicket.new(plate, size)
      @tickets[ticket.license_plate] = ticket
      { success: true, message: result, ticket: ticket }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    result = @garage.exit_car(plate)
    return { success: false, message: result } if result == "No space available"

    ticket = @tickets.delete(plate_str)
    duration = ticket ? ticket.duration_hours : 0.0
    fee = ticket ? @fee_calculator.calculate_fee(ticket.car_size, duration) : 0.0

    { success: true, message: result, fee: fee.to_f, duration_hours: duration.round(2) }
  end

  def garage_status
    total_available = @garage.available_small + @garage.available_medium + @garage.available_large
    total_occupied = @total_spots - total_available
    {
      small_available: @garage.available_small,
      medium_available: @garage.available_medium,
      large_available: @garage.available_large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tickets.fetch(plate.to_s.strip, nil)
  end
end