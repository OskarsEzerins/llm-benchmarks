require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i

    @parking_spots = {
      tiny_spot:   [],
      mid_spot:    [],
      grande_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    kar = { plate: license_plate_no.to_s, size: car_size }

    case car_size.downcase
    when 'small'
      if @small > 0
        @parking_spots[:tiny_spot] << kar
        @small -= 1
        return parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return parking_status
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return shuffle_medium(kar)
      end

    when 'large'
      if @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return shuffle_large(kar)
      end
    end

    "No space available"
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s

    small_car = @parking_spots[:tiny_spot].find { |c| c[:plate] == plate }
    medium_car = @parking_spots[:mid_spot].find { |c| c[:plate] == plate }
    large_car = @parking_spots[:grande_spot].find { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:tiny_spot].delete(small_car)
      @small += 1
      return exit_status(plate)
    elsif medium_car
      @parking_spots[:mid_spot].delete(medium_car)
      @medium += 1
      return exit_status(plate)
    elsif large_car
      @parking_spots[:grande_spot].delete(large_car)
      @large += 1
      return exit_status(plate)
    else
      return exit_status
    end
  end

  def shuffle_medium(kar)
    # Find a small car in medium or large spot to move to small spot
    candidates = @parking_spots[:mid_spot].select { |c| c[:size] == 'small' } +
                 @parking_spots[:grande_spot].select { |c| c[:size] == 'small' }

    if @small > 0 && !candidates.empty?
      victim = candidates.first
      if @parking_spots[:mid_spot].include?(victim)
        @parking_spots[:mid_spot].delete(victim)
      else
        @parking_spots[:grande_spot].delete(victim)
      end

      @parking_spots[:tiny_spot] << victim
      @small -= 1

      # Now park the medium car
      @parking_spots[:mid_spot] << kar
      @medium -= 1

      return parking_status(kar, 'medium')
    end

    "No space available"
  end

  def shuffle_large(kar)
    # Find a medium car in large spot to move to medium spot
    candidates = @parking_spots[:grande_spot].select { |c| c[:size] == 'medium' }

    if @medium > 0 && !candidates.empty?
      victim = candidates.first
      @parking_spots[:grande_spot].delete(victim)
      @parking_spots[:mid_spot] << victim
      @medium -= 1

      # Now park the large car
      @parking_spots[:grande_spot] << kar
      @large -= 1

      return parking_status(kar, 'large')
    end

    # If no medium cars in large spot, check for small cars
    small_candidates = @parking_spots[:grande_spot].select { |c| c[:size] == 'small' }

    if @medium > 0 && !small_candidates.empty?
      victim = small_candidates.first
      @parking_spots[:grande_spot].delete(victim)
      @parking_spots[:mid_spot] << victim
      @medium -= 1

      # Now park the large car
      @parking_spots[:grande_spot] << kar
      @large -= 1

      return parking_status(kar, 'large')
    end

    "No space available"
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
      "Ghost car?"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate
    @car_size = car_size
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
    "TK-#{SecureRandom.hex(4).upcase}"
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
    return 0.0 if duration_hours < 0

    # Grace period: first 15 minutes (0.25 hours) free
    if duration_hours <= 0.25
      return 0.0
    end

    # Round up partial hours to next full hour
    hours = duration_hours.ceil

    # Calculate fee
    rate = RATES[car_size] || 0
    total = hours * rate

    # Apply daily maximum
    max_fee = MAX_FEE[car_size] || Float::INFINITY
    [total, max_fee].min
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(license_plate, car_size)
    # Input validation
    return { success: false, message: "Invalid license plate" } if license_plate.nil? || license_plate.to_s.strip.empty?
    return { success: false, message: "Invalid car size" } unless ['small', 'medium', 'large'].include?(car_size.to_s.downcase)

    plate = license_plate.to_s
    size = car_size.to_s.downcase

    result = @garage.admit_car(plate, size)

    if result.include?("parked")
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(license_plate)
    plate = license_plate.to_s
    ticket = @tix_in_flight[plate]

    return { success: false, message: "Ticket not found" } unless ticket

    # Calculate fee before removing the car
    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)

    # Remove car from garage
    result = @garage.exit_car(plate)

    # Remove ticket from active tickets
    @tix_in_flight.delete(plate)

    { success: true, message: result, fee: fee, duration_hours: duration }
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

  def find_ticket(license_plate)
    @tix_in_flight[license_plate.to_s]
  end

  private

  def total_occupied
    (@garage.instance_variable_get(:@parking_spots)[:tiny_spot].length +
     @garage.instance_variable_get(:@parking_spots)[:mid_spot].length +
     @garage.instance_variable_get(:@parking_spots)[:grande_spot].length)
  end

  def total_available
    @garage.small + @garage.medium + @garage.large
  end
end