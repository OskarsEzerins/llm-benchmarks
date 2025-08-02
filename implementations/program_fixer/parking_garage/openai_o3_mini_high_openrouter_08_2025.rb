require 'securerandom'

class ParkingGarage
  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @parking_spots = {
      tiny_spot:   [],
      mid_spot:    [],
      grande_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    license_plate_no = license_plate_no.to_s.strip
    car_size = car_size.to_s.downcase.strip
    return "Invalid input" if license_plate_no.empty? || !%w[small medium large].include?(car_size)
    car = { plate: license_plate_no, size: car_size }
    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:tiny_spot] << car
        @small -= 1
        return parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:mid_spot] << car
        @medium -= 1
        return parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << car
        @large -= 1
        return parking_status(car, 'large')
      else
        return parking_status
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:mid_spot] << car
        @medium -= 1
        return parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << car
        @large -= 1
        return parking_status(car, 'large')
      else
        return shuffle_medium(car)
      end
    when 'large'
      if @large > 0
        @parking_spots[:grande_spot] << car
        @large -= 1
        return parking_status(car, 'large')
      else
        return shuffle_large(car)
      end
    else
      return "Invalid car size"
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s.strip
    small_car  = @parking_spots[:tiny_spot].find { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:mid_spot].find { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:grande_spot].find { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:tiny_spot].delete(small_car)
      @small += 1
      return exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:mid_spot].delete(medium_car)
      @medium += 1
      return exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:grande_spot].delete(large_car)
      @large += 1
      return exit_status(license_plate_no)
    else
      return exit_status
    end
  end

  def shuffle_medium(car)
    if !@parking_spots[:mid_spot].empty? && @small > 0
      victim = @parking_spots[:mid_spot].sample
      @parking_spots[:mid_spot].delete(victim)
      @parking_spots[:tiny_spot] << victim
      @small -= 1
      @parking_spots[:mid_spot] << car
      return parking_status(car, 'medium')
    else
      "No space available"
    end
  end

  def shuffle_large(car)
    # For a large car, try to shuffle a medium car from the large spot if possible.
    medium_in_large = @parking_spots[:grande_spot].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium > 0
      @parking_spots[:grande_spot].delete(medium_in_large)
      @parking_spots[:mid_spot] << medium_in_large
      @medium -= 1
      @parking_spots[:grande_spot] << car
      return parking_status(car, 'large')
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
    if plate
      "car with license plate no. #{plate} exited"
    else
      "Ghost car?"
    end
  end

  def available_small
    @small
  end

  def available_medium
    @medium
  end

  def available_large
    @large
  end

  def total_occupied
    @parking_spots[:tiny_spot].size + @parking_spots[:mid_spot].size + @parking_spots[:grande_spot].size
  end

  def total_available
    @small + @medium + @large
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase.strip
    @entry_time = entry_time + rand(60)
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24
  end
end

class ParkingFeeCalculator
  SMALL_RATE = 2.0
  MEDIUM_RATE = 3.0
  LARGE_RATE = 5.0

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= 0.25
    car_size = car_size.to_s.downcase.strip
    rate = case car_size
           when 'small'
             SMALL_RATE
           when 'medium'
             MEDIUM_RATE
           when 'large'
             LARGE_RATE
           else
             0.0
           end
    # Subtract grace period and then round up to next whole hour.
    effective_hours = (duration_hours - 0.25).ceil
    total = effective_hours * rate
    fee = total > MAX_FEE[car_size] ? MAX_FEE[car_size] : total
    fee.to_f
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    plate = plate.to_s.strip
    size = size.to_s.downcase.strip
    return { ok: false, msg: "Invalid input" } if plate.empty? || !%w[small medium large].include?(size)
    result = @garage.admit_car(plate, size)
    if result.include?("parked")
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate] = ticket
      { ok: true, msg: result, tix: ticket }
    else
      { ok: false, msg: result }
    end
  end

  def exit_car(plate)
    plate = plate.to_s.strip
    ticket = @tickets[plate]
    return { ok: false, msg: 'Ticket not found' } unless ticket
    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)
    @tickets.delete(plate)
    { ok: true, msg: result, fee: fee, hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.available_small,
      medium_available: @garage.available_medium,
      large_available: @garage.available_large,
      total_occupied: @garage.total_occupied,
      total_available: @garage.total_available,
      tickets_in_flight: @tickets.size
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s.strip]
  end
end