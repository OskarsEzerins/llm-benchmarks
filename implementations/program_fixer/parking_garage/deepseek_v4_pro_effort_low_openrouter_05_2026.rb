require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

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
    plate = license_plate_no.to_s
    size  = car_size.to_s.downcase
    kar   = { plate: plate, size: size }

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
        parking_status
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
        parking_status
      end

    when 'large'
      if @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end

    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s

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
      exit_status
    end
  end

  private

  def shuffle_large(kar)
    first_medium = @parking_spots[:grande_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:grande_spot].delete(first_medium)
      @large += 1
      @parking_spots[:mid_spot] << first_medium
      @medium -= 1
      @parking_spots[:grande_spot] << kar
      @large -= 1
      return parking_status(kar, 'large')
    end
    parking_status
  end

  def parking_status(car = nil, spot_type = nil)
    if car && spot_type
      "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      "No car found"
    end
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s
    @entry_time    = entry_time
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
    small:  2.0,
    medium: 3.0,
    large:  5.0
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  def calculate_fee(car_size, duration_hours)
    return -1 if duration_hours.nil? || duration_hours < 0
    return 0.0 if car_size.nil?

    size_key = car_size.to_s.downcase
    rate = RATES[size_key.to_sym]
    return 0.0 unless rate

    max_fee = MAX_FEE[size_key] || 0.0

    if duration_hours <= 0.25
      0.0
    else
      chargeable = duration_hours - 0.25
      hours = chargeable.ceil
      fee = hours * rate
      [fee, max_fee].min
    end
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @tix_in_flight   = {}
    @total_spots     = small_spots.to_i + medium_spots.to_i + large_spots.to_i
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    return { success: false, message: 'Invalid license plate' } if plate_str.empty?

    car_size_str = size.to_s.downcase
    unless %w[small medium large].include?(car_size_str)
      return { success: false, message: 'Invalid car size' }
    end

    verdict = @garage.admit_car(plate_str, car_size_str)

    if verdict.include?('parked')
      ticket = ParkingTicket.new(plate_str, car_size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    return { success: false, message: 'Invalid license plate' } if plate_str.empty?

    ticket = @tix_in_flight[plate_str]
    return { success: false, message: 'Ticket not found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)

    @tix_in_flight.delete(plate_str)

    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    available_small  = @garage.small
    available_medium = @garage.medium
    available_large  = @garage.large
    total_available  = available_small + available_medium + available_large
    total_occupied   = @total_spots - total_available

    {
      small_available:  available_small,
      medium_available: available_medium,
      large_available:  available_large,
      total_occupied:   total_occupied,
      total_available:  total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end