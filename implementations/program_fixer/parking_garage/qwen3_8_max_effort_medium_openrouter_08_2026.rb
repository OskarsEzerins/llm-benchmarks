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

    plate = license_plate_no.to_s
    size = car_size.to_s.strip.downcase

    unless %w[small medium large].include?(size)
      return "No space available"
    end

    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    return exit_status if license_plate_no.nil?

    plate = license_plate_no.to_s

    small_car  = @parking_spots[:small].detect  { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium].detect { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large].detect  { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      exit_status(plate)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      exit_status(plate)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      exit_status(plate)
    else
      exit_status
    end
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large].delete(first_medium)
      @parking_spots[:medium] << first_medium
      @parking_spots[:large] << kar
      parking_status(kar, 'large')
    else
      parking_status
    end
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
      "No space available"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.strip.downcase
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
    return 0.0 if duration_hours.nil? || !duration_hours.is_a?(Numeric) || duration_hours < 0
    return 0.0 if car_size.nil?

    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    return 0.0 if duration_hours <= GRACE_PERIOD

    hours = duration_hours.ceil
    rate  = RATES[size]
    total = hours * rate

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
    if plate.nil? || plate.to_s.strip.empty?
      return { success: false, message: "No space available", ticket: nil }
    end

    if size.nil? || !%w[small medium large].include?(size.to_s.strip.downcase)
      return { success: false, message: "No space available", ticket: nil }
    end

    plate_str = plate.to_s
    size_str  = size.to_s.strip.downcase

    verdict = @garage.admit_car(plate_str, size_str)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict, ticket: nil }
    end
  end

  def exit_car(plate)
    return { success: false, message: "No space available", fee: 0.0, duration_hours: 0.0 } if plate.nil?

    plate_str = plate.to_s
    ticket = @tix_in_flight[plate_str]

    unless ticket
      return { success: false, message: "No space available", fee: 0.0, duration_hours: 0.0 }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)

    @tix_in_flight.delete(plate_str)

    { success: true, message: result, fee: fee.to_f, duration_hours: duration }
  end

  def garage_status
    small_avail  = @garage.small
    medium_avail = @garage.medium
    large_avail  = @garage.large
    total_available = small_avail + medium_avail + large_avail
    total_spots = @garage.parking_spots[:small].size + @garage.parking_spots[:medium].size + @garage.parking_spots[:large].size + total_available
    total_occupied = total_spots - total_available

    {
      small_available: small_avail,
      medium_available: medium_avail,
      large_available: large_avail,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?
    @tix_in_flight.fetch(plate.to_s, nil)
  end
end