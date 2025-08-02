require 'securerandom'
require 'time'

class ParkingGarage
  attr_reader :small_spots, :medium_spots, :large_spots, :parking_spots

  def initialize(small_count, medium_count, large_count)
    @small_spots  = small_count.to_i
    @medium_spots = medium_count.to_i
    @large_spots  = large_count.to_i

    @parking_spots = {
      small:   [],
      medium:  [],
      large:   []
    }
  end

  def admit_car(license_plate, car_size)
    # Input validation
    license_plate = license_plate.to_s.strip
    return "Invalid license plate" if license_plate.empty?
    car_size = car_size.to_s.downcase
    unless ['small', 'medium', 'large'].include?(car_size)
      return "Invalid car size: #{car_size}"
    end

    car_info = { plate: license_plate, size: car_size }

    case car_size
    when 'small'
      if @small_spots > 0
        @parking_spots[:small] << car_info
        @small_spots -= 1
        return "car with license plate no. #{license_plate} is parked at small"
      elsif @medium_spots > 0
        @parking_spots[:medium] << car_info
        @medium_spots -= 1
        return "car with license plate no. #{license_plate} is parked at medium"
      elsif @large_spots > 0
        @parking_spots[:large] << car_info
        @large_spots -= 1
        return "car with license plate no. #{license_plate} is parked at large"
      else
        return "No space available"
      end

    when 'medium'
      if @medium_spots > 0
        @parking_spots[:medium] << car_info
        @medium_spots -= 1
        return "car with license plate no. #{license_plate} is parked at medium"
      elsif @large_spots > 0
        @parking_spots[:large] << car_info
        @large_spots -= 1
        return "car with license plate no. #{license_plate} is parked at large"
      else
        # Attempt to shuffle a medium car into a small spot if a large spot is occupied by a medium car
        if shuffle_medium_to_small(car_info)
          return "car with license plate no. #{license_plate} is parked at small (shuffled)"
        else
          return "No space available"
        end
      end

    when 'large'
      if @large_spots > 0
        @parking_spots[:large] << car_info
        @large_spots -= 1
        return "car with license plate no. #{license_plate} is parked at large"
      else
        # Attempt to shuffle a large car into a medium spot if a medium spot is occupied by a large car
        if shuffle_large_to_medium(car_info)
          return "car with license plate no. #{license_plate} is parked at medium (shuffled)"
        else
          return "No space available"
        end
      end
    end
  end

  def exit_car(license_plate)
    license_plate = license_plate.to_s.strip
    return nil if license_plate.empty?

    spot_type = nil
    car_to_remove = nil

    [:small, :medium, :large].each do |type|
      car_to_remove = @parking_spots[type].find { |c| c[:plate] == license_plate }
      if car_to_remove
        spot_type = type
        break
      end
    end

    if car_to_remove
      @parking_spots[spot_type].delete(car_to_remove)
      case spot_type
      when :small
        @small_spots += 1
      when :medium
        @medium_spots += 1
      when :large
        @large_spots += 1
      end
      return { plate: license_plate, spot: spot_type }
    else
      return nil
    end
  end

  def available_spots
    {
      small: @small_spots,
      medium: @medium_spots,
      large: @large_spots
    }
  end

  def total_occupied
    @parking_spots.values.flatten.size
  end

  private

  def shuffle_medium_to_small(car_info)
    # Find a medium car parked in a small spot (shouldn't happen with current admit_car logic, but for completeness)
    # Or a large car parked in a medium spot that can be moved to a small spot.
    # This is a simplified shuffle: if a medium spot is occupied by a large car and a small spot is free.
    if @small_spots > 0 && @medium_spots < @medium_spots + @large_spots # Check if there are medium cars parked in large spots
      # Find a medium car in a large spot
      medium_in_large_index = @parking_spots[:large].find_index { |c| c[:size] == 'medium' }
      if medium_in_large_index
        car_to_move = @parking_spots[:large].delete_at(medium_in_large_index)
        @parking_spots[:medium] << car_to_move
        @large_spots += 1 # Free up a large spot
        @medium_spots -= 1 # Occupy a medium spot

        @parking_spots[:small] << car_info
        @small_spots -= 1
        return true
      end
    end
    false
  end

  def shuffle_large_to_medium(car_info)
    # Find a medium car parked in a large spot and move it to a medium spot.
    if @medium_spots > 0
      medium_in_large_index = @parking_spots[:large].find_index { |c| c[:size] == 'medium' }
      if medium_in_large_index
        car_to_move = @parking_spots[:large].delete_at(medium_in_large_index)
        @parking_spots[:medium] << car_to_move
        @large_spots += 1 # Free up a large spot
        @medium_spots -= 1 # Occupy a medium spot

        @parking_spots[:medium] << car_info
        @medium_spots -= 1
        return true
      end
    end
    false
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase
    @entry_time = Time.now
  end

  def duration_hours
    duration = Time.now - @entry_time
    # Convert duration to hours, rounding up partial hours
    (duration / 3600.0).ceil
  end

  def valid?
    # Tickets are valid for 24 hours. The fee calculation will handle the duration.
    true
  end
end

class ParkingFeeCalculator
  RATES_PER_HOUR = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }

  DAILY_MAXIMUMS = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  GRACE_PERIOD_HOURS = 0.25 # 15 minutes

  def calculate_fee(car_size, duration_hours)
    car_size = car_size.to_s.downcase

    # Input validation for fee calculation
    unless RATES_PER_HOUR.key?(car_size) && duration_hours.is_a?(Numeric) && duration_hours >= 0
      return -1.0 # Indicate an error or invalid input
    end

    # Apply grace period
    if duration_hours <= GRACE_PERIOD_HOURS
      return 0.0
    end

    # Calculate billable hours, rounding up partial hours
    billable_hours = (duration_hours).ceil

    # Calculate fee based on hourly rate
    hourly_rate = RATES_PER_HOUR[car_size]
    calculated_fee = billable_hours * hourly_rate

    # Apply daily maximum
    daily_max = DAILY_MAXIMUMS[car_size]
    final_fee = [calculated_fee, daily_max].min

    final_fee
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets_in_flight = {}
  end

  def admit_car(plate, size)
    license_plate = plate.to_s.strip
    car_size = size.to_s.downcase

    # Input validation for admit_car
    return { success: false, message: "Invalid license plate" } if license_plate.empty?
    unless ['small', 'medium', 'large'].include?(car_size)
      return { success: false, message: "Invalid car size: #{size}" }
    end

    admission_result = @garage.admit_car(license_plate, car_size)

    if admission_result.start_with?("car with license plate no.")
      ticket = ParkingTicket.new(license_plate, car_size)
      @tickets_in_flight[license_plate] = ticket
      { success: true, message: admission_result, ticket: ticket }
    else
      { success: false, message: admission_result }
    end
  end

  def exit_car(plate)
    license_plate = plate.to_s.strip

    # Input validation for exit_car
    return { success: false, message: "Invalid license plate" } if license_plate.empty?

    ticket = @tickets_in_flight[license_plate]
    return { success: false, message: "No active ticket found for license plate #{license_plate}" } unless ticket

    exit_details = @garage.exit_car(license_plate)
    unless exit_details
      return { success: false, message: "Failed to remove car from garage for license plate #{license_plate}" }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)

    @tickets_in_flight.delete(license_plate)

    {
      success: true,
      message: "car with license plate no. #{license_plate} exited",
      fee: fee,
      duration_hours: duration,
      spot_type: exit_details[:spot]
    }
  end

  def garage_status
    available = @garage.available_spots
    {
      small_available: available[:small],
      medium_available: available[:medium],
      large_available: available[:large],
      total_occupied: @garage.total_occupied,
      total_available: available.values.sum
    }
  end

  def find_ticket(plate)
    license_plate = plate.to_s.strip
    @tickets_in_flight[license_plate]
  end
end