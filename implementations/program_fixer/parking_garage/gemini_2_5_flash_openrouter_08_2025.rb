require 'securerandom'

class ParkingGarage
  attr_reader :small_available, :medium_available, :large_available, :parking_spots

  def initialize(small_spots, medium_spots, large_spots)
    @small_available  = small_spots.to_i
    @medium_available = medium_spots.to_i
    @large_available  = large_spots.to_i

    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate, car_size)
    car_size = car_size.to_s.downcase

    # Input validation
    return "Invalid car size: #{car_size}" unless ['small', 'medium', 'large'].include?(car_size)
    return "Invalid license plate" if license_plate.to_s.strip.empty?

    car = { plate: license_plate.to_s, size: car_size }

    case car_size
    when 'small'
      if @small_available > 0
        @parking_spots[:small] << car
        @small_available -= 1
        return parking_status_message(car, 'small')
      elsif @medium_available > 0
        @parking_spots[:medium] << car
        @medium_available -= 1
        return parking_status_message(car, 'medium')
      elsif @large_available > 0
        @parking_spots[:large] << car
        @large_available -= 1
        return parking_status_message(car, 'large')
      else
        return "No space available"
      end

    when 'medium'
      if @medium_available > 0
        @parking_spots[:medium] << car
        @medium_available -= 1
        return parking_status_message(car, 'medium')
      elsif @large_available > 0
        @parking_spots[:large] << car
        @large_available -= 1
        return parking_status_message(car, 'large')
      else
        return shuffle_medium_for_large_spot(car) || "No space available"
      end

    when 'large'
      if @large_available > 0
        @parking_spots[:large] << car
        @large_available -= 1
        return parking_status_message(car, 'large')
      else
        return shuffle_large_for_large_spot(car) || "No space available"
      end
    end
  end

  def exit_car(license_plate)
    license_plate = license_plate.to_s

    [:small, :medium, :large].each do |spot_type|
      car_to_exit = @parking_spots[spot_type].find { |c| c[:plate] == license_plate }
      if car_to_exit
        @parking_spots[spot_type].delete(car_to_exit)
        send("#{spot_type}_available=", send("#{spot_type}_available") + 1) # Increment available spot
        return exit_status_message(license_plate)
      end
    end
    "Car with license plate no. #{license_plate} not found"
  end

  private

  def shuffle_medium_for_large_spot(new_car)
    # Find a medium car in a large spot to move it to a medium spot
    medium_car_in_large_spot = @parking_spots[:large].find { |c| c[:size] == 'medium' }

    if medium_car_in_large_spot && @medium_available > 0
      @parking_spots[:large].delete(medium_car_in_large_spot)
      @parking_spots[:medium] << medium_car_in_large_spot
      @medium_available -= 1 # This spot is now taken by the shuffled car

      @parking_spots[:large] << new_car
      # The large spot was freed by shuffling, so now it's taken by the new car
      # @large_available doesn't change here, as one large spot was freed and immediately taken.
      return parking_status_message(new_car, 'large')
    end
    nil
  end

  def shuffle_large_for_large_spot(new_car)
    # Find a medium car in a large spot and move it to a medium spot, if available.
    # This frees up a large spot for a new large car.
    medium_car_in_large_spot = @parking_spots[:large].find { |c| c[:size] == 'medium' }

    if medium_car_in_large_spot && @medium_available > 0
      @parking_spots[:large].delete(medium_car_in_large_spot)
      @parking_spots[:medium] << medium_car_in_large_spot
      @medium_available -= 1 # This spot is now taken by the shuffled car

      @parking_spots[:large] << new_car
      # The large spot was freed by shuffling, so now it's taken by the new car
      # @large_available doesn't change here, as one large spot was freed and immediately taken.
      return parking_status_message(new_car, 'large')
    end
    nil
  end

  def parking_status_message(car, space_type)
    "car with license plate no. #{car[:plate]} is parked at #{space_type}"
  end

  def exit_status_message(plate)
    "car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    (Time.now - @entry_time).to_f / 3600.0
  end

  def valid?
    # Tickets expire after 24 hours
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }.freeze

  GRACE_PERIOD_HOURS = 0.25 # 15 minutes

  DAILY_MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  def calculate_fee(car_size, duration_hours)
    car_size = car_size.to_s.downcase
    return 0.0 if duration_hours.nil? || !duration_hours.is_a?(Numeric) || duration_hours < 0

    # Grace period
    return 0.0 if duration_hours <= GRACE_PERIOD_HOURS

    # Round up partial hours to next full hour
    billed_hours = duration_hours.ceil

    rate = RATES[car_size]
    return 0.0 unless rate # Should not happen with validation

    total_fee = billed_hours * rate

    # Apply daily maximum
    max_fee = DAILY_MAX_FEE[car_size]
    [total_fee, max_fee].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets_in_flight = {}
  end

  def admit_car(license_plate, car_size)
    # Basic input validation for license_plate and car_size
    license_plate = license_plate.to_s.strip
    car_size = car_size.to_s.downcase

    if license_plate.empty?
      return { success: false, message: "License plate cannot be empty." }
    end

    unless ['small', 'medium', 'large'].include?(car_size)
      return { success: false, message: "Invalid car size. Must be 'small', 'medium', or 'large'." }
    end

    # Check if car is already parked
    if @tickets_in_flight.key?(license_plate)
      return { success: false, message: "Car with license plate #{license_plate} is already parked." }
    end

    parking_result = @garage.admit_car(license_plate, car_size)

    if parking_result.start_with?("car with license plate no.")
      ticket = ParkingTicket.new(license_plate, car_size)
      @tickets_in_flight[license_plate] = ticket
      { success: true, message: parking_result, ticket: ticket }
    else
      { success: false, message: parking_result }
    end
  end

  def exit_car(license_plate)
    license_plate = license_plate.to_s.strip

    ticket = @tickets_in_flight[license_plate]
    unless ticket
      return { success: false, message: "Car with license plate no. #{license_plate} not found or not parked." }
    end

    unless ticket.valid?
      # This case might be handled by the fee calculation, but adding explicit check
      # For simplicity, we allow exit even if ticket is "invalid" but charge fee.
      # return { success: false, message: "Ticket for #{license_plate} expired." }
    end

    duration_hours = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration_hours)

    exit_message = @garage.exit_car(license_plate)

    @tickets_in_flight.delete(license_plate)

    { success: true, message: exit_message, fee: fee, duration_hours: duration_hours }
  end

  def garage_status
    {
      small_available:   @garage.small_available,
      medium_available:  @garage.medium_available,
      large_available:   @garage.large_available,
      total_occupied:    @tickets_in_flight.size,
      total_available:   @garage.small_available + @garage.medium_available + @garage.large_available
    }
  end

  def find_ticket(license_plate)
    @tickets_in_flight.fetch(license_plate.to_s.strip, nil)
  end
end