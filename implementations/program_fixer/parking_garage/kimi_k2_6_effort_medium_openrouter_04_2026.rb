require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :total_small, :total_medium, :total_large

  def initialize(small, medium, large)
    @total_small = small.to_i
    @total_medium = medium.to_i
    @total_large = large.to_i
    @small = @total_small
    @medium = @total_medium
    @large = @total_large
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    return "No space available" if plate.empty?

    size = car_size.to_s.downcase.strip
    return "No space available" unless %w[small medium large].include?(size)

    already_parked = @parking_spots.values.any? { |spot| spot.any? { |c| c[:plate] == plate } }
    return "No space available" if already_parked

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << { plate: plate, size: size }
        @small -= 1
        "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << { plate: plate, size: size }
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << { plate: plate, size: size }
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << { plate: plate, size: size }
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << { plate: plate, size: size }
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << { plate: plate, size: size }
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        shuffle_large(plate, size)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    return "No car found" if plate.strip.empty?

    car = @parking_spots[:small].find { |c| c[:plate].to_s == plate }
    if car
      @parking_spots[:small].delete(car)
      @small += 1
      return "car with license plate no. #{plate} exited"
    end

    car = @parking_spots[:medium].find { |c| c[:plate].to_s == plate }
    if car
      @parking_spots[:medium].delete(car)
      @medium += 1
      return "car with license plate no. #{plate} exited"
    end

    car = @parking_spots[:large].find { |c| c[:plate].to_s == plate }
    if car
      @parking_spots[:large].delete(car)
      @large += 1
      return "car with license plate no. #{plate} exited"
    end

    "No car found"
  end

  private

  def shuffle_large(plate, size)
    medium_car = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_car && @medium > 0
      @parking_spots[:large].delete(medium_car)
      @parking_spots[:medium] << medium_car
      @medium -= 1
      @parking_spots[:large] << { plate: plate, size: size }
      "car with license plate no. #{plate} is parked at large"
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
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours <= 0.25

    normalized_size = car_size.to_s.downcase
    rate = RATES[normalized_size] || 0.0
    return 0.0 if rate == 0.0

    chargeable_hours = duration_hours - 0.25
    hours = [chargeable_hours.ceil, 0].max
    total = hours * rate
    max_fee = MAX_FEE[normalized_size] || 0.0
    [total, max_fee].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    normalized_plate = plate.to_s.strip
    return { success: false, message: "No space available" } if normalized_plate.empty?

    verdict = @garage.admit_car(normalized_plate, size)
    if verdict.include?('is parked at')
      ticket = ParkingTicket.new(normalized_plate, size)
      @tix_in_flight[normalized_plate] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    normalized_plate = plate.to_s.strip
    ticket = @tix_in_flight[normalized_plate]

    unless ticket
      return { success: false, message: "No active ticket found" }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(normalized_plate)
    @tix_in_flight.delete(normalized_plate)

    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    total_occupied = (@garage.total_small - @garage.small) +
                     (@garage.total_medium - @garage.medium) +
                     (@garage.total_large - @garage.large)
    total_available = @garage.small + @garage.medium + @garage.large

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end
end