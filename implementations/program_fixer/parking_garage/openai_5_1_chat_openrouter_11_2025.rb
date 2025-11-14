require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i
    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size  = car_size.to_s.downcase.strip
    return "No space available" if plate.empty?
    return "No space available" unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }

    if size == 'small'
      return park(car, :small)  if @small > 0
      return park(car, :medium) if @medium > 0
      return park(car, :large)  if @large > 0
      return "No space available"
    end

    if size == 'medium'
      return park(car, :medium) if @medium > 0
      return park(car, :large)  if @large > 0
      return "No space available"
    end

    if size == 'large'
      return park(car, :large) if @large > 0
      return "No space available"
    end

    "No space available"
  end

  def park(car, type)
    @parking_spots[type] << car
    instance_variable_set("@#{type}", instance_variable_get("@#{type}") - 1)
    "car with license plate no. #{car[:plate]} is parked at #{type}"
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    %i[small medium large].each do |type|
      found = @parking_spots[type].find { |c| c[:plate] == plate }
      if found
        @parking_spots[type].delete(found)
        instance_variable_set("@#{type}", instance_variable_get("@#{type}") + 1)
        return "car with license plate no. #{plate} exited"
      end
    end
    "car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id          = SecureRandom.uuid
    @license     = license_plate.to_s
    @car_size    = car_size.to_s.downcase
    @entry_time  = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).to_f
  end

  def valid?
    duration_hours <= 24
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
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 if duration_hours <= 0.25

    hours = duration_hours.ceil
    fee = hours * RATES[size]
    [fee, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)
    if verdict.include?("parked")
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate = plate.to_s
    ticket = @tix_in_flight[plate]
    return { success: false, message: "No active ticket" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)
    @tix_in_flight.delete(plate)

    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
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
    @tix_in_flight[plate.to_s]
  end
end