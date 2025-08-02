require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small_spot:   [],
      medium_spot:  [],
      large_spot:   []
    }
  end

  def admit_car(license_plate_no, car_size)
    sanitized_plate = sanitize_plate(license_plate_no)
    return "Invalid license plate" unless sanitized_plate
    sanitized_size = sanitize_size(car_size)
    return "Invalid car size" unless sanitized_size

    car = { plate: sanitized_plate, size: sanitized_size }

    case sanitized_size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_medium(car) || "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car) || "No space available"
      end
    else
      "Invalid car size"
    end
  end

  def exit_car(license_plate_no)
    sanitized_plate = sanitize_plate(license_plate_no)
    return "Invalid license plate" unless sanitized_plate

    car, spot_type = find_car(sanitized_plate)
    return "Car not found" unless car

    @parking_spots[spot_type].delete(car)
    increment_spot(spot_type)
    exit_status(sanitized_plate)
  end

  private

  def sanitize_plate(plate)
    return nil if plate.nil?
    plate_str = plate.to_s.strip
    plate_str.empty? ? nil : plate_str
  end

  def sanitize_size(size)
    return nil if size.nil?
    size_str = size.to_s.downcase.strip
    %w[small medium large].include?(size_str) ? size_str : nil
  end

  def find_car(plate)
    [:small_spot, :medium_spot, :large_spot].each do |spot|
      car = @parking_spots[spot].find { |c| c[:plate] == plate }
      return [car, spot] if car
    end
    [nil, nil]
  end

  def increment_spot(spot)
    case spot
    when :small_spot
      @small += 1
    when :medium_spot
      @medium += 1
    when :large_spot
      @large += 1
    end
  end

  def shuffle_medium(car)
    victim = (@parking_spots[:medium_spot] + @parking_spots[:large_spot]).sample
    return nil unless victim

    spot = @parking_spots[:medium_spot].include?(victim) ? :medium_spot : :large_spot
    @parking_spots[spot].delete(victim)
    @parking_spots[:small_spot] << victim
    @small -= 1
    @parking_spots[spot] << car
    @medium -= 1 if spot == :medium_spot
    @large -= 1 if spot == :large_spot
    parking_status(car, 'small')
  end

  def shuffle_large(car)
    victim = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    return nil unless victim && @medium > 0

    @parking_spots[:large_spot].delete(victim)
    @parking_spots[:medium_spot] << victim
    @medium -= 1
    @parking_spots[:large_spot] << car
    @large -= 1
    parking_status(car, 'large')
  end

  def parking_status(car, space)
    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate)
    "car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id          = generate_ticket_id
    @license     = license_plate.to_s.strip
    @car_size    = car_size.downcase
    @entry_time  = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(2)
  end

  def valid?
    duration_hours <= 24
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
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
    return -1.0 unless valid_inputs?(car_size, duration_hours)

    return 0.0 if duration_hours <= GRACE_PERIOD

    billable_hours = (duration_hours - GRACE_PERIOD).ceil
    rate = RATES[car_size] || 0.0
    total = billable_hours * rate
    [total, MAX_FEE[car_size]].min
  end

  private

  def valid_inputs?(car_size, duration_hours)
    return false if car_size.nil? || duration_hours.nil?
    return false unless RATES.key?(car_size)
    return false unless duration_hours.is_a?(Numeric) && duration_hours >= 0
    true
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets_in_flight = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)
    if result.start_with?("car with license plate no.")
      ticket = ParkingTicket.new(plate, size)
      @tickets_in_flight[ticket.id] = { ticket: ticket, plate: ticket.instance_variable_get(:@license) }
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    ticket_info = @tickets_in_flight.find { |_, v| v[:plate] == plate.to_s.strip }
    return { success: false, message: 'No active ticket for this plate' } unless ticket_info

    ticket = ticket_info[1][:ticket]
    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    message = @garage.exit_car(plate)
    @tickets_in_flight.delete(ticket_info[0])
    { success: true, message: message, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    ticket_info = @tickets_in_flight.find { |_, v| v[:plate] == plate.to_s.strip }
    ticket_info ? ticket_info[1][:ticket] : nil
  end

  private

  def total_occupied
    total_spots = initial_spots
    total_spots - (@garage.small + @garage.medium + @garage.large)
  end

  def total_available
    @garage.small + @garage.medium + @garage.large
  end

  def initial_spots
    @initial_spots ||= @garage.small + @garage.medium + @garage.large
  end
end