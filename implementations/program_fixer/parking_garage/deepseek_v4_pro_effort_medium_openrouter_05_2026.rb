require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      tiny_spot:   [],
      mid_spot:    [],
      grande_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "No space available" if license_plate_no.nil? || car_size.nil?

    plate = license_plate_no.to_s.strip
    size  = car_size.to_s.downcase.strip

    return "No space available" if plate.empty? || !['small', 'medium', 'large'].include?(size)

    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:tiny_spot] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip

    small_car  = @parking_spots[:tiny_spot].find   { |c| c[:plate] == plate }
    medium_car = @parking_spots[:mid_spot].find    { |c| c[:plate] == plate }
    large_car  = @parking_spots[:grande_spot].find { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:tiny_spot].delete(small_car)
      @small += 1
      exit_status(plate)
    elsif medium_car
      @parking_spots[:mid_spot].delete(medium_car)
      @medium += 1
      exit_status(plate)
    elsif large_car
      @parking_spots[:grande_spot].delete(large_car)
      @large += 1
      exit_status(plate)
    else
      "car with license plate no. #{plate} not found"
    end
  end

  private

  def shuffle_large(kar)
    first_medium = @parking_spots[:grande_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:grande_spot].delete(first_medium)
      @parking_spots[:mid_spot] << first_medium
      @large += 1
      @medium -= 1
      @parking_spots[:grande_spot] << kar
      parking_status(kar, 'large')
    else
      "No space available"
    end
  end

  def parking_status(car, space)
    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate)
    "car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
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
    small: 2.0,
    medium: 3.0,
    large: 5.0
  }.freeze

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || !duration_hours.is_a?(Numeric) || duration_hours < 0
    return 0.0 if duration_hours <= 0.25

    size = car_size.to_s.downcase.strip
    rate = RATES[size.to_sym] || 0.0
    return 0.0 if rate == 0.0

    chargeable = duration_hours - 0.25
    hours = chargeable.ceil
    fee = hours * rate
    max = MAX_FEE[size] || 0.0
    [fee, max].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @total_small  = small_spots.to_i
    @total_medium = medium_spots.to_i
    @total_large  = large_spots.to_i
    @garage        = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "No space available" } if plate.nil? || size.nil?

    plate_str = plate.to_s.strip
    size_str  = size.to_s.strip.downcase

    return { success: false, message: "No space available" } if plate_str.empty? || !['small', 'medium', 'large'].include?(size_str)

    result = @garage.admit_car(plate_str, size_str)

    if result.to_s.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tix_in_flight[plate_str]

    unless ticket
      return { success: false, message: 'No active ticket found' }
    end

    fee    = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)
    @tix_in_flight.delete(plate_str)

    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    available_small  = @garage.small
    available_medium = @garage.medium
    available_large  = @garage.large
    total_occupied = (@total_small + @total_medium + @total_large) - (available_small + available_medium + available_large)
    total_available = available_small + available_medium + available_large

    {
      small_available: available_small,
      medium_available: available_medium,
      large_available: available_large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end
end