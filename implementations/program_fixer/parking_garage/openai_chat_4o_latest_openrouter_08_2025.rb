require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

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
    license_plate_no = license_plate_no.to_s.strip
    return "Invalid license plate" if license_plate_no.empty?
    car_size = car_size.to_s.downcase.strip
    return "Invalid car size" unless %w[small medium large].include?(car_size)

    car = { plate: license_plate_no, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        return "car with license plate no. #{license_plate_no} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{license_plate_no} is parked at large"
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{license_plate_no} is parked at large"
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{license_plate_no} is parked at large"
      end
    end

    "No space available"
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s.strip
    [[:small, :@small], [:medium, :@medium], [:large, :@large]].each do |spot, counter|
      car = @parking_spots[spot].find { |c| c[:plate] == license_plate_no }
      if car
        @parking_spots[spot].delete(car)
        instance_variable_set(counter, instance_variable_get(counter) + 1)
        return "car with license plate no. #{license_plate_no} exited"
      end
    end
    "Car not found"
  end

  def status
    {
      small_available: @small,
      medium_available: @medium,
      large_available: @large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  private

  def total_occupied
    @parking_spots.values.map(&:size).sum
  end

  def total_available
    @small + @medium + @large
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    duration = (Time.now - @entry_time) / 3600.0
    duration.round(2)
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
    return 0.0 unless RATES.key?(car_size)
    return 0.0 if duration_hours <= 0.25

    hours = duration_hours.ceil
    fee = hours * RATES[car_size]
    [fee, MAX_FEE[car_size]].min.to_f
  rescue
    0.0
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(license_plate, car_size)
    license_plate = license_plate.to_s.strip
    car_size = car_size.to_s.downcase.strip
    return { success: false, message: "Invalid license plate" } if license_plate.empty?
    return { success: false, message: "Invalid car size" } unless %w[small medium large].include?(car_size)

    result = @garage.admit_car(license_plate, car_size)

    if result.start_with?("car with license plate no.")
      ticket = ParkingTicket.new(license_plate, car_size)
      @active_tickets[license_plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(license_plate)
    license_plate = license_plate.to_s.strip
    ticket = @active_tickets[license_plate]
    return { success: false, message: "Ticket not found" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(license_plate)

    @active_tickets.delete(license_plate)

    {
      success: true,
      message: result,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    status = @garage.status
    {
      small_available: status[:small_available],
      medium_available: status[:medium_available],
      large_available: status[:large_available],
      total_occupied: status[:total_occupied],
      total_available: status[:total_available]
    }
  end

  def find_ticket(license_plate)
    @active_tickets[license_plate.to_s.strip]
  end
end