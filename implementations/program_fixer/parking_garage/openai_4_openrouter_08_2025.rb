require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

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
    car = { plate: license_plate_no, size: car_size }

    case car_size.downcase
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        "No space available"
      end
    else
      "Invalid car size"
    end
  end

  def exit_car(license_plate_no)
    [:small_spot, :medium_spot, :large_spot].each do |spot|
      car = @parking_spots[spot].find { |c| c[:plate].to_s == license_plate_no.to_s }
      if car
        @parking_spots[spot].delete(car)
        update_availability(spot)
        return exit_status(license_plate_no)
      end
    end
    "Car not found"
  end

  def garage_status
    {
      small_available: @small,
      medium_available: @medium,
      large_available: @large,
      total_occupied: @small + @medium + @large,
      total_available: @parking_spots.values.flatten.count
    }
  end

  private

  def update_availability(spot)
    case spot
    when :small_spot
      @small += 1
    when :medium_spot
      @medium += 1
    when :large_spot
      @large += 1
    end
  end

  def parking_status(car, space)
    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate)
    "car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id           = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size     = car_size.downcase
    @entry_time   = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600).round(2)
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
    return 0.0 if duration_hours <= 0.25
    hours = duration_hours.ceil
    rate  = RATES[car_size] || 0.0
    total = hours * rate
    [total, MAX_FEE[car_size] || 0.0].min
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)

    if result.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    ticket = @tix_in_flight[plate.to_s]
    return { success: false, message: 'No ticket found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)
    @tix_in_flight.delete(plate.to_s)

    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    @garage.garage_status.merge({ active_tickets: @tix_in_flight.size })
  end
end