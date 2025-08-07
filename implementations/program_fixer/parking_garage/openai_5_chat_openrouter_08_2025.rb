require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i
    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    license_plate_no = license_plate_no.to_s.strip
    return "No space available" if license_plate_no.empty?
    size = normalize_size(car_size)
    return "No space available" unless %w[small medium large].include?(size)

    car = { plate: license_plate_no, size: size }
    case size
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
        shuffle_medium(car) || "No space available"
      end
    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car) || "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s.strip
    small_car  = @parking_spots[:small_spot].find { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium_spot].find { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:large_spot].find { |c| c[:plate] == license_plate_no }

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
      "No such car found"
    end
  end

  def shuffle_medium(car)
    victim = @parking_spots[:medium_spot].find { true }
    return nil unless victim && @small > 0
    @parking_spots[:medium_spot].delete(victim)
    @parking_spots[:small_spot] << victim
    @small -= 1
    @parking_spots[:medium_spot] << car
    @medium -= 1
    parking_status(car, 'medium')
  end

  def shuffle_large(car)
    first_medium = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large_spot].delete(first_medium)
      @parking_spots[:medium_spot] << first_medium
      @medium -= 1
      @parking_spots[:large_spot] << car
      @large -= 1
      return parking_status(car, 'large')
    end
    nil
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
      "No such car found"
    end
  end

  private

  def normalize_size(size)
    size.to_s.strip.downcase
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size      = car_size.to_s.strip.downcase
    @entry_time    = entry_time
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
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 if duration_hours <= 0.25
    hours = duration_hours.ceil
    total = hours * RATES[size]
    [total, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    res = @garage.admit_car(plate, size)
    if res.start_with?("car with license plate no.")
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s.strip] = ticket
      { success: true, message: res, ticket: ticket }
    else
      { success: false, message: res }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tix_in_flight[plate_str]
    return { success: false, message: "No ticket found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)
    @tix_in_flight.delete(plate_str)
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
    @tix_in_flight[plate.to_s.strip]
  end
end