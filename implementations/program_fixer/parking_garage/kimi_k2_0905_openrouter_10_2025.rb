require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "No space available" if license_plate_no.nil? || license_plate_no.to_s.strip.empty?
    return "No space available" unless %w[small medium large].include?(car_size.to_s.downcase)

    plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase
    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip

    small_car  = @parking_spots[:small].detect { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium].detect { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large].detect { |c| c[:plate] == plate }

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
      "car with license plate no. #{plate} exited"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(1)
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
    return 0.0 if duration_hours.nil? || duration_hours < 0
    return 0.0 if duration_hours <= 0.25

    hours = (duration_hours - 0.25).ceil
    size = car_size.to_s.downcase
    rate = RATES[size] || 0.0
    total = hours * rate
    [total, MAX_FEE[size] || 999.0].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "No space available" } if plate.nil? || plate.to_s.strip.empty?
    return { success: false, message: "No space available" } unless %w[small medium large].include?(size.to_s.downcase)

    verdict = @garage.admit_car(plate, size)

    if verdict.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s.strip] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    return { success: false, message: "nope" } if plate.nil?

    ticket = @tix_in_flight[plate.to_s.strip]
    return { success: false, message: "nope" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate.to_s.strip)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @tix_in_flight.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?
    @tix_in_flight[plate.to_s.strip]
  end
end