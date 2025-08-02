require 'securerandom'
require 'time'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i
    @parking_spots = {
      small_spot:  [],
      medium_spot: [],
      large_spot:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "No space available" if license_plate_no.to_s.strip.empty? || !['small', 'medium', 'large'].include?(car_size.to_s.downcase)
    car = { plate: license_plate_no.to_s, size: car_size.to_s.downcase }

    case car_size.to_s.downcase
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
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s
    small_car  = @parking_spots[:small_spot].detect { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium_spot].detect { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:large_spot].detect { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      exit_status(license_plate_no)
    else
      "Car not found"
    end
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : "Car not found"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id           = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size     = car_size.to_s.downcase
    @entry_time   = entry_time
  end

  def duration_hours
    ((Time.now - entry_time) / 3600).to_f
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
    return 0.0 if duration_hours.to_f <= 0.25
    return 0.0 if duration_hours.to_f < 0
    hours = duration_hours.to_f.ceil
    rate  = RATES[car_size.to_s.downcase] || 0.0
    total = hours * rate
    [total, MAX_FEE[car_size.to_s.downcase] || 0.0].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @tix_in_flight   = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid input" } if plate.to_s.strip.empty? || !['small', 'medium', 'large'].include?(size.to_s.downcase)
    verdict = @garage.admit_car(plate, size.to_s.downcase)

    if verdict.include?('parked')
      ticket               = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    ticket = @tix_in_flight[plate.to_s]
    return { success: false, message: "Ticket not found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate.to_s)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    total_occupied = @garage.parking_spots.values.flatten.size
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end