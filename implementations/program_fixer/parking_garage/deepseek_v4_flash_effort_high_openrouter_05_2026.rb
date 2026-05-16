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
    car = { plate: license_plate_no.to_s, size: car_size.downcase }

    case car_size.downcase
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        "car with license plate no. #{car[:plate]} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{car[:plate]} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{car[:plate]} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{car[:plate]} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{car[:plate]} is parked at large"
      else
        shuffle_medium(car)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{car[:plate]} is parked at large"
      else
        shuffle_large(car)
      end

    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    car = @parking_spots[:small].find { |c| c[:plate] == plate }
    if car
      @parking_spots[:small].delete(car)
      @small += 1
      return "car with license plate no. #{plate} exited"
    end

    car = @parking_spots[:medium].find { |c| c[:plate] == plate }
    if car
      @parking_spots[:medium].delete(car)
      @medium += 1
      return "car with license plate no. #{plate} exited"
    end

    car = @parking_spots[:large].find { |c| c[:plate] == plate }
    if car
      @parking_spots[:large].delete(car)
      @large += 1
      return "car with license plate no. #{plate} exited"
    end

    "No car found with license plate no. #{plate}"
  end

  private

  def shuffle_medium(car)
    # Try to move a small car from a medium spot to a small spot to free a medium spot
    victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
    if victim && @small > 0
      @parking_spots[:medium].delete(victim)
      @parking_spots[:small] << victim
      @small -= 1
      @medium += 1  # medium spot freed
      @parking_spots[:medium] << car
      @medium -= 1
      "car with license plate no. #{car[:plate]} is parked at medium"
    else
      "No space available"
    end
  end

  def shuffle_large(car)
    # Try to move a medium car from a large spot to a medium spot to free a large spot
    victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if victim && @medium > 0
      @parking_spots[:large].delete(victim)
      @parking_spots[:medium] << victim
      @medium -= 1
      @large += 1  # large spot freed
      @parking_spots[:large] << car
      @large -= 1
      "car with license plate no. #{car[:plate]} is parked at large"
    else
      "No space available"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.downcase
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
  RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours < 0
    size = car_size.to_s.downcase
    rate = RATES[size]
    return 0.0 unless rate  # invalid size

    # Grace period: first 15 minutes free
    if duration_hours <= 0.25
      return 0.0
    end

    billable_hours = (duration_hours - 0.25).ceil
    total = billable_hours * rate
    max = MAX_FEE[size] || Float::INFINITY
    [total, max].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    # Input validation
    plate_str = plate.to_s.strip
    size_str = size.to_s.downcase.strip
    unless %w[small medium large].include?(size_str)
      return { success: false, message: "No space available" }
    end
    if plate_str.empty?
      return { success: false, message: "No space available" }
    end

    result = @garage.admit_car(plate_str, size_str)
    if result.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @active_tickets[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @active_tickets[plate_str]
    return { success: false, message: "No active ticket for #{plate_str}" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)
    @active_tickets.delete(plate_str)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    total_spots = @garage.small + @garage.medium + @garage.large
    total_occupied = @active_tickets.size
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   total_occupied,
      total_available:  total_spots
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end