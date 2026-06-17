require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

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
    return "No space available" if license_plate_no.nil?
    plate_str = license_plate_no.to_s
    return "No space available" if plate_str.strip.empty?

    size = normalize_size(car_size)
    return "No space available" if size.nil?

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
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate_str} is parked at large"
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    plate_str = license_plate_no.to_s

    [:small, :medium, :large].each do |spot_type|
      car = @parking_spots[spot_type].find { |c| c[:plate] == plate_str }
      if car
        @parking_spots[spot_type].delete(car)
        case spot_type
        when :small
          @small += 1
        when :medium
          @medium += 1
        when :large
          @large += 1
        end
        return "car with license plate no. #{plate_str} exited"
      end
    end

    "car with license plate no. #{plate_str} not found"
  end

  private

  def normalize_size(car_size)
    return nil if car_size.nil?
    size = car_size.to_s.downcase.strip
    return nil unless ['small', 'medium', 'large'].include?(size)
    size
  end

  def shuffle_large(car)
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium > 0
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium -= 1
      @parking_spots[:large] << car
      return "car with license plate no. #{car[:plate]} is parked at large"
    end

    small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if small_in_large && @small > 0
      @parking_spots[:large].delete(small_in_large)
      @parking_spots[:small] << small_in_large
      @small -= 1
      @parking_spots[:large] << car
      return "car with license plate no. #{car[:plate]} is parked at large"
    end

    if small_in_large && @medium > 0
      @parking_spots[:large].delete(small_in_large)
      @parking_spots[:medium] << small_in_large
      @medium -= 1
      @parking_spots[:large] << car
      return "car with license plate no. #{car[:plate]} is parked at large"
    end

    "No space available"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24
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
    return 0.0 if duration_hours.nil?
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours < 0

    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)

    return 0.0 if duration_hours <= GRACE_PERIOD

    billable_hours = (duration_hours - GRACE_PERIOD).ceil
    rate = RATES[size]
    total = billable_hours * rate

    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "No space available" } if plate.nil?
    plate_str = plate.to_s
    return { success: false, message: "No space available" } if plate_str.strip.empty?

    return { success: false, message: "No space available" } if size.nil?
    size_normalized = size.to_s.downcase.strip
    return { success: false, message: "No space available" } unless ['small', 'medium', 'large'].include?(size_normalized)

    result = @garage.admit_car(plate_str, size_normalized)

    if result.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_normalized)
      @active_tickets[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @active_tickets[plate_str]
    return { success: false, message: "car with license plate no. #{plate_str} not found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)

    @active_tickets.delete(plate_str)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @active_tickets.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s]
  end
end