require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "No space available" if license_plate_no.nil?
    plate_str = license_plate_no.to_s.strip
    return "No space available" if plate_str.empty?

    size = car_size.to_s.downcase.strip
    return "No space available" unless %w[small medium large].include?(size)

    car = { plate: plate_str, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        "car with license plate no. #{plate_str} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{plate_str} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate_str} is parked at large"
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{plate_str} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate_str} is parked at large"
      else
        if shuffle_medium(car)
          "car with license plate no. #{plate_str} is parked at medium"
        else
          "No space available"
        end
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate_str} is parked at large"
      else
        if shuffle_large(car)
          "car with license plate no. #{plate_str} is parked at large"
        else
          "No space available"
        end
      end
    end
  end

  def exit_car(license_plate_no)
    return "car not found" if license_plate_no.nil?
    plate_str = license_plate_no.to_s.strip
    return "car not found" if plate_str.empty?

    small_car = @parking_spots[:small].find { |c| c[:plate] == plate_str }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate_str }
    large_car = @parking_spots[:large].find { |c| c[:plate] == plate_str }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      "car with license plate no. #{plate_str} exited"
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      "car with license plate no. #{plate_str} exited"
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      "car with license plate no. #{plate_str} exited"
    else
      "car not found"
    end
  end

  private

  def shuffle_medium(kar)
    victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
    return false unless victim && @small > 0

    @parking_spots[:medium].delete(victim)
    @parking_spots[:small] << victim
    @small -= 1
    @medium += 1

    @parking_spots[:medium] << kar
    @medium -= 1
    true
  end

  def shuffle_large(kar)
    victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    return false unless victim && @medium > 0

    @parking_spots[:large].delete(victim)
    @parking_spots[:medium] << victim
    @medium -= 1
    @large += 1

    @parking_spots[:large] << kar
    @large -= 1
    true
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase.strip
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24.0
  end

  private

  def generate_ticket_id
    "TK-#{rand(9999)}"
  end
end

class ParkingFeeCalculator
  RATES = {
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours.respond_to?(:nan?) && duration_hours.nan?
    return 0.0 if duration_hours.respond_to?(:infinite?) && duration_hours.infinite?
    return 0.0 if duration_hours <= 0.25

    size = car_size.to_s.downcase.strip
    rate = RATES[size]
    max = MAX_FEE[size]
    return 0.0 unless rate && max

    hours = duration_hours.ceil
    total = hours * rate
    [total, max].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    if plate.nil? || plate.to_s.strip.empty?
      return { success: false, message: "No space available" }
    end

    size_str = size.to_s.downcase.strip
    unless %w[small medium large].include?(size_str)
      return { success: false, message: "No space available" }
    end

    verdict = @garage.admit_car(plate, size_str)

    if verdict.include?('parked')
      ticket = ParkingTicket.new(plate, size_str)
      @tix_in_flight[plate.to_s.strip] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tix_in_flight[plate_str]

    unless ticket
      return { success: false, message: "No active ticket found" }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)

    @tix_in_flight.delete(plate_str)

    { success: true, message: result, fee: fee.to_f, duration_hours: ticket.duration_hours }
  end

  def garage_status
    small_avail = @garage.small
    medium_avail = @garage.medium
    large_avail = @garage.large
    total_avail = small_avail + medium_avail + large_avail
    total_occupied = @tix_in_flight.size

    {
      small_available: small_avail,
      medium_available: medium_avail,
      large_available: large_avail,
      total_occupied: total_occupied,
      total_available: total_avail
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end
end