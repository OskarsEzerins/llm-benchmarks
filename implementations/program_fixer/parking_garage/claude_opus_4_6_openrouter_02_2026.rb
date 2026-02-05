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
    return parking_status if license_plate_no.nil? || car_size.nil?

    license_plate_no = license_plate_no.to_s.strip
    return parking_status if license_plate_no.empty?

    car_size = car_size.to_s.strip.downcase
    return parking_status unless %w[small medium large].include?(car_size)

    kar = { plate: license_plate_no, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    return exit_status if license_plate_no.nil?

    license_plate_no = license_plate_no.to_s.strip
    return exit_status if license_plate_no.empty?

    small_car  = @parking_spots[:small_spot].find  { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium_spot].find  { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:large_spot].find   { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      exit_status(license_plate_no)
    else
      exit_status
    end
  end

  def shuffle_medium(kar)
    # Find a small car in medium spots that can be moved to a small spot
    victim = @parking_spots[:medium_spot].find { |c| c[:size] == 'small' }

    if victim && @small > 0
      @parking_spots[:medium_spot].delete(victim)
      @parking_spots[:small_spot] << victim
      @small -= 1
      @parking_spots[:medium_spot] << kar
      parking_status(kar, 'medium')
    else
      parking_status
    end
  end

  def shuffle_large(kar)
    # Find a medium car in large spots that can be moved to a medium spot
    first_medium = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large_spot].delete(first_medium)
      @parking_spots[:medium_spot] << first_medium
      @medium -= 1
      @parking_spots[:large_spot] << kar
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
      "Car not found"
    end
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id           = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size     = car_size.to_s.strip.downcase
    @entry_time   = entry_time
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
    return 0.0 if car_size.nil? || duration_hours.nil?

    car_size = car_size.to_s.strip.downcase
    duration_hours = duration_hours.to_f

    return 0.0 if duration_hours < 0
    return 0.0 if duration_hours <= GRACE_PERIOD

    rate = RATES[car_size]
    return 0.0 unless rate

    hours = duration_hours.ceil
    total = hours * rate
    [total, MAX_FEE[car_size] || total].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid input" } if plate.nil? || size.nil?

    plate = plate.to_s.strip
    size  = size.to_s.strip.downcase

    return { success: false, message: "Invalid input" } if plate.empty?
    return { success: false, message: "Invalid input" } unless %w[small medium large].include?(size)

    verdict = @garage.admit_car(plate, size)

    if verdict.to_s.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    return { success: false, message: "Invalid input" } if plate.nil?

    plate = plate.to_s.strip
    return { success: false, message: "Invalid input" } if plate.empty?

    ticket = @tix_in_flight[plate]
    return { success: false, message: "Car not found" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @tix_in_flight.size,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?
    plate = plate.to_s.strip
    @tix_in_flight[plate]
  end
end