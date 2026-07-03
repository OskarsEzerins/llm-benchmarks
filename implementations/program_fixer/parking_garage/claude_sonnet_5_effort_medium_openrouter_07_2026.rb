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
    return "No space available" if license_plate_no.nil? || license_plate_no.to_s.strip.empty?
    return "No space available" if car_size.nil?

    plate = license_plate_no.to_s
    size  = car_size.to_s.downcase
    car   = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        success_message(plate, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        success_message(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        success_message(plate, 'large')
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        success_message(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        success_message(plate, 'large')
      else
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        success_message(plate, 'large')
      else
        "No space available"
      end

    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s

    small_car  = @parking_spots[:small].find  { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large].find  { |c| c[:plate] == plate }

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
      "Car not found"
    end
  end

  private

  def success_message(plate, spot_type)
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id             = generate_ticket_id
    @license_plate  = license_plate.to_s
    @car_size       = car_size.to_s.downcase
    @entry_time     = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || duration_hours < 0

    size = car_size.to_s.downcase
    rate = RATES[size]
    return 0.0 unless rate

    return 0.0 if duration_hours <= GRACE_PERIOD

    hours = duration_hours.ceil
    total = (hours * rate).to_f
    max   = MAX_FEE[size] || total

    [total, max].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "No space available" } if plate.nil? || plate.to_s.strip.empty?
    return { success: false, message: "No space available" } if size.nil?

    normalized_size = size.to_s.downcase
    unless %w[small medium large].include?(normalized_size)
      return { success: false, message: "No space available" }
    end

    result = @garage.admit_car(plate, normalized_size)

    if result.to_s.include?('is parked at')
      ticket = ParkingTicket.new(plate, normalized_size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    key    = plate.to_s
    ticket = @tix_in_flight[key]
    return { success: false, message: "No active ticket found" } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(plate)

    @tix_in_flight.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    small_available  = @garage.small
    medium_available = @garage.medium
    large_available  = @garage.large
    total_occupied   = @tix_in_flight.size
    total_available  = small_available + medium_available + large_available

    {
      small_available:  small_available,
      medium_available: medium_available,
      large_available:  large_available,
      total_occupied:   total_occupied,
      total_available:  total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end