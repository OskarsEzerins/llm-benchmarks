require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large = [large.to_i, 0].max
    @initial_small = @small
    @initial_medium = @medium
    @initial_large = @large
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def total_capacity
    @initial_small + @initial_medium + @initial_large
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    return "Invalid license plate" if plate.empty?

    size = car_size.to_s.downcase.strip
    return "Invalid car size" unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        park(car, :small)
      elsif @medium > 0
        park(car, :medium)
      elsif @large > 0
        park(car, :large)
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        park(car, :medium)
      elsif @large > 0
        park(car, :large)
      else
        "No space available"
      end
    when 'large'
      if @large > 0
        park(car, :large)
      else
        if shuffle_large(car)
          park(car, :large)
        else
          "No space available"
        end
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    return "Invalid license plate" if plate.empty?

    spot_type = @parking_spots.keys.find do |type|
      @parking_spots[type].any? { |c| c[:plate] == plate }
    end
    return "car with license plate no. #{plate} not found" unless spot_type

    car = @parking_spots[spot_type].find { |c| c[:plate] == plate }
    @parking_spots[spot_type].delete(car)

    case spot_type
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end

    "car with license plate no. #{plate} exited"
  end

  private

  def park(car, spot_type)
    @parking_spots[spot_type] << car

    case spot_type
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end

    "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
  end

  def shuffle_large(car)
    medium_car = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_car && @medium > 0
      @parking_spots[:large].delete(medium_car)
      @large += 1
      @parking_spots[:medium] << medium_car
      @medium -= 1
      return true
    end

    small_car = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if small_car && @small > 0
      @parking_spots[:large].delete(small_car)
      @large += 1
      @parking_spots[:small] << small_car
      @small -= 1
      return true
    end

    if small_car && @medium > 0
      @parking_spots[:large].delete(small_car)
      @large += 1
      @parking_spots[:medium] << small_car
      @medium -= 1
      return true
    end

    false
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
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

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
  end
end

class ParkingFeeCalculator
  RATES = {
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }.freeze

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase.strip
    return 0.0 unless RATES.key?(size)

    duration = duration_hours.to_f
    return 0.0 if duration < 0
    return 0.0 if duration <= 0.25

    hours = duration.ceil
    fee = hours * RATES[size]
    [fee, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)

    if result.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s.strip] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    key = plate.to_s.strip
    ticket = @tix_in_flight[key]
    return { success: false, message: "No active ticket for #{key}" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(key)
    @tix_in_flight.delete(key)

    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.total_capacity - total_available,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end
end