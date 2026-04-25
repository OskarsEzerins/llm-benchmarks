require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.strip.downcase

    return "No space available" if plate.empty?
    return "No space available" unless %w[small medium large].include?(size)

    case size
    when 'small'
      if @small > 0
        @spots[:small] << { plate: plate, size: size }
        @small -= 1
        "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @spots[:medium] << { plate: plate, size: size }
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @spots[:large] << { plate: plate, size: size }
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        @spots[:medium] << { plate: plate, size: size }
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @spots[:large] << { plate: plate, size: size }
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    when 'large'
      if @large > 0
        @spots[:large] << { plate: plate, size: size }
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        try_shuffle_large(plate, size)
      end
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip

    car = @spots[:small].find { |c| c[:plate] == plate }
    if car
      @spots[:small].delete(car)
      @small += 1
      return "car with license plate no. #{plate} exited"
    end

    car = @spots[:medium].find { |c| c[:plate] == plate }
    if car
      @spots[:medium].delete(car)
      @medium += 1
      return "car with license plate no. #{plate} exited"
    end

    car = @spots[:large].find { |c| c[:plate] == plate }
    if car
      @spots[:large].delete(car)
      @large += 1
      return "car with license plate no. #{plate} exited"
    end

    "No car found"
  end

  def total_occupied
    @spots.values.sum(&:size)
  end

  def total_available
    @small + @medium + @large
  end

  private

  def try_shuffle_large(plate, size)
    medium_in_large = @spots[:large].find { |c| c[:size] == 'medium' }

    if medium_in_large && @medium > 0
      @spots[:large].delete(medium_in_large)
      @large += 1

      @spots[:medium] << medium_in_large
      @medium -= 1

      @spots[:large] << { plate: plate, size: size }
      @large -= 1

      "car with license plate no. #{plate} is parked at large"
    else
      "No space available"
    end
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
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

  private

  def generate_ticket_id
    SecureRandom.uuid
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
    return 0.0 if duration_hours.nil?

    hours = duration_hours.to_f
    return 0.0 if hours < 0
    return 0.0 if hours <= 0.25

    size = car_size.to_s.strip.downcase
    rate = RATES[size]
    return 0.0 unless rate

    total_hours = hours.ceil
    total = total_hours * rate
    max_fee = MAX_FEE[size] || total

    [total, max_fee].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str = size.to_s.strip.downcase

    if plate_str.empty? || !%w[small medium large].include?(size_str)
      return { success: false, message: "Invalid input" }
    end

    result = @garage.admit_car(plate_str, size_str)

    if result == "No space available"
      { success: false, message: "No space available" }
    else
      ticket = ParkingTicket.new(plate_str, size_str)
      @active_tickets[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip

    ticket = @active_tickets[plate_str]
    unless ticket
      return { success: false, message: "No active ticket found" }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)
    @active_tickets.delete(plate_str)

    {
      success: true,
      message: result,
      fee: fee.to_f,
      duration_hours: ticket.duration_hours
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.total_occupied,
      total_available: @garage.total_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end