require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

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
    return "No space available" if license_plate_no.nil? || license_plate_no.to_s.strip.empty?
    return "No space available" if car_size.nil?

    car_size = car_size.to_s.downcase.strip
    return "No space available" unless ['small', 'medium', 'large'].include?(car_size)

    license_plate_no = license_plate_no.to_s
    car = { plate: license_plate_no, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        "car with license plate no. #{license_plate_no} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        shuffle_medium(car, license_plate_no)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        shuffle_large(car, license_plate_no)
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s

    small_car  = @parking_spots[:small].detect { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium].detect { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:large].detect { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      "car with license plate no. #{license_plate_no} exited"
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      "car with license plate no. #{license_plate_no} exited"
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      "car with license plate no. #{license_plate_no} exited"
    else
      nil
    end
  end

  def shuffle_medium(car, license_plate_no)
    large_car = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if large_car && @medium > -1
      @parking_spots[:large].delete(large_car)
      @parking_spots[:medium] << large_car
      @medium -= 1
      @parking_spots[:large] << car
      @large -= 1
      "car with license plate no. #{license_plate_no} is parked at large"
    else
      "No space available"
    end
  end

  def shuffle_large(car, license_plate_no)
    small_car = @parking_spots[:small].find { |c| c[:size] == 'small' }
    medium_car = @parking_spots[:medium].find { |c| c[:size] == 'medium' }

    if small_car && @small > -1
      @parking_spots[:small].delete(small_car)
      @parking_spots[:large] << small_car
      @small -= 1
      @parking_spots[:large] << car
      @large -= 1
      "car with license plate no. #{license_plate_no} is parked at large"
    elsif medium_car && @medium > -1
      @parking_spots[:medium].delete(medium_car)
      @parking_spots[:large] << medium_car
      @medium -= 1
      @parking_spots[:large] << car
      @large -= 1
      "car with license plate no. #{license_plate_no} is parked at large"
    else
      "No space available"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate_no

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate_no = license_plate.to_s
    @car_size = car_size.to_s.downcase
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || duration_hours < 0
    
    car_size = car_size.to_s.downcase.strip
    return 0.0 unless RATES.key?(car_size)

    if duration_hours <= GRACE_PERIOD
      return 0.0
    end

    billable_hours = duration_hours - GRACE_PERIOD
    hours = billable_hours.ceil
    rate = RATES[car_size]
    total = hours * rate

    [total, MAX_FEE[car_size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "No space available" } if plate.nil? || plate.to_s.strip.empty?
    return { success: false, message: "No space available" } if size.nil?

    size = size.to_s.downcase.strip
    return { success: false, message: "No space available" } unless ['small', 'medium', 'large'].include?(size)

    plate = plate.to_s
    verdict = @garage.admit_car(plate, size)

    if verdict.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    return { success: false, message: "No ticket found" } if plate.nil?

    plate = plate.to_s
    ticket = @tix_in_flight[plate]
    return { success: false, message: "No ticket found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    return { success: false, message: "Car not found in garage" } if result.nil?

    @tix_in_flight.delete(plate)
    {
      success: true,
      message: result,
      fee: fee,
      duration_hours: ticket.duration_hours
    }
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
    @tix_in_flight.fetch(plate.to_s, nil)
  end
end