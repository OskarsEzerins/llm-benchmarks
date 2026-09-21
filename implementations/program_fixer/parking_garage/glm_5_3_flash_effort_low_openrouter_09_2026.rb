require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small_spot:  [],
      medium_spot: [],
      large_spot:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    return 'No space available' if license_plate_no.nil? || car_size.nil?
    return 'No space available' if license_plate_no.to_s.strip.empty?

    plate = license_plate_no.to_s
    size  = car_size.to_s.downcase.strip

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small.positive?
        @parking_spots[:small_spot] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium.positive?
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large.positive?
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end
    when 'medium'
      if @medium.positive?
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large.positive?
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end
    when 'large'
      if @large.positive?
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end
    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    return 'No space available' if license_plate_no.nil?
    plate = license_plate_no.to_s

    small_car  = @parking_spots[:small_spot].detect  { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium_spot].detect { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large_spot].detect  { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      exit_status(plate)
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      exit_status(plate)
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      exit_status(plate)
    else
      exit_status
    end
  end

  def total_available
    @small + @medium + @large
  end

  def total_occupied
    @parking_spots.values.map(&:size).sum
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : 'No space available'
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id             = "TK-#{SecureRandom.uuid}"
    @license_plate  = license_plate.to_s
    @car_size       = car_size.to_s.downcase
    @entry_time     = entry_time
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
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if car_size.nil? || duration_hours.nil?
    return 0.0 unless RATES.key?(car_size.to_s.downcase)
    return 0.0 if duration_hours.to_f.negative?

    size  = car_size.to_s.downcase
    hours = duration_hours.to_f

    return 0.0 if hours <= GRACE_PERIOD

    billable = (hours - GRACE_PERIOD).ceil
    total    = billable * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate.to_s, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: 'No space available' }
    end
  end

  def exit_car(plate)
    key    = plate.to_s
    ticket = @tix_in_flight[key]

    unless ticket
      return { success: false, message: "no active ticket for license plate no. #{key}" }
    end

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(key)

    @tix_in_flight.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @garage.total_occupied,
      total_available:  @garage.total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end