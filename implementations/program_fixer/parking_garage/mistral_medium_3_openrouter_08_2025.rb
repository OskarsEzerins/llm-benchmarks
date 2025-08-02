require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "Invalid car size" unless ['small', 'medium', 'large'].include?(car_size.downcase)
    return "Invalid license plate" if license_plate_no.to_s.strip.empty?

    car_size = car_size.downcase
    car = { plate: license_plate_no.to_s, size: car_size }

    case car_size
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
        shuffle_medium(car)
      end
    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s
    small_car = @parking_spots[:small_spot].find { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium_spot].find { |c| c[:plate] == license_plate_no }
    large_car = @parking_spots[:large_spot].find { |c| c[:plate] == license_plate_no }

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

  def shuffle_medium(car)
    victim = (@parking_spots[:small_spot] + @parking_spots[:medium_spot]).sample
    return "No space available" unless victim

    where = @parking_spots.key(victim)
    @parking_spots[where].delete(victim)
    @parking_spots[:small_spot] << victim
    @small -= 1
    @parking_spots[where] << car
    parking_status(car, where.to_s.sub('_spot', ''))
  end

  def shuffle_large(car)
    first_medium = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large_spot].delete(first_medium)
      @parking_spots[:medium_spot] << first_medium
      @parking_spots[:large_spot] << car
      @medium -= 1
      parking_status(car, 'large')
    else
      "No space available"
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
    @id = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size = car_size.downcase
    @entry_time = entry_time
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0].max.round(2)
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
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
    return 0.0 if duration_hours <= 0.25
    return 0.0 unless RATES.key?(car_size.downcase)

    car_size = car_size.downcase
    hours = [duration_hours.ceil - 0.25, 0].max
    rate = RATES[car_size]
    total = hours * rate
    [total, MAX_FEE[car_size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets_in_flight = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid license plate" } if plate.to_s.strip.empty?
    return { success: false, message: "Invalid car size" } unless ['small', 'medium', 'large'].include?(size.downcase)

    result = @garage.admit_car(plate, size)

    if result.is_a?(String) && result.include?("is parked at")
      ticket = ParkingTicket.new(plate, size)
      @tickets_in_flight[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result || "No space available" }
    end
  end

  def exit_car(plate)
    plate = plate.to_s
    ticket = @tickets_in_flight[plate]
    return { success: false, message: "Ticket not found" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate)

    @tickets_in_flight.delete(plate)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @tickets_in_flight.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tickets_in_flight[plate.to_s]
  end
end