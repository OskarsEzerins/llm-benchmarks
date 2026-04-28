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
    plate = license_plate_no.to_s
    size = car_size.to_s.downcase
    return "No space available" unless ['small', 'medium', 'large'].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        shuffle_medium(car)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    small_car  = @parking_spots[:small].find { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large].find { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      "car with license plate no. #{plate} exited"
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      "car with license plate no. #{plate} exited"
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      "car with license plate no. #{plate} exited"
    else
      "No space available"
    end
  end

  def shuffle_medium(car)
    victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
    return "No space available" unless victim && @small > 0

    @parking_spots[:medium].delete(victim)
    @parking_spots[:small] << victim
    @medium += 1
    @small -= 1

    @parking_spots[:medium] << car
    @medium -= 1

    "car with license plate no. #{car[:plate]} is parked at medium"
  end

  def shuffle_large(car)
    victim = @parking_spots[:large].find { |c| c[:size] != 'large' }
    return "No space available" unless victim

    can_move = victim[:size] == 'small' ? @small > 0 : @medium > 0
    return "No space available" unless can_move

    @parking_spots[:large].delete(victim)
    @large += 1

    if victim[:size] == 'small'
      @parking_spots[:small] << victim
      @small -= 1
    else
      @parking_spots[:medium] << victim
      @medium -= 1
    end

    @parking_spots[:large] << car
    "car with license plate no. #{car[:plate]} is parked at large"
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
    (Time.now - entry_time) / 3600.0
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
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  def calculate_fee(car_size, duration_hours)
    car_size = car_size.to_s.downcase
    duration = duration_hours.to_f

    return 0.0 if duration <= 0.25

    billable_hours = (duration - 0.25).ceil
    return 0.0 if billable_hours <= 0

    rate = RATES[car_size] || 0.0
    total = billable_hours * rate
    max_fee = MAX_FEE[car_size] || Float::INFINITY
    [total, max_fee].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets_in_flight = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "No space available" } if plate.nil? || size.nil?
    plate = plate.to_s
    return { success: false, message: "No space available" } if plate.strip.empty?

    size_str = size.to_s.downcase
    return { success: false, message: "No space available" } unless ['small', 'medium', 'large'].include?(size_str)

    message = @garage.admit_car(plate, size_str)

    if message.include?('parked')
      ticket = ParkingTicket.new(plate, size_str)
      @tickets_in_flight[plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    plate = plate.to_s
    return { success: false, message: "No space available" } unless @tickets_in_flight.key?(plate)

    ticket = @tickets_in_flight[plate]
    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate)

    @tickets_in_flight.delete(plate)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large
    total_occupied = @garage.parking_spots.values.flatten.size

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tickets_in_flight[plate.to_s]
  end
end