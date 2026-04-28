require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

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
    return nil if license_plate_no.nil? || license_plate_no.to_s.strip.empty?
    return nil if car_size.nil?

    normalized_size = car_size.to_s.strip.downcase
    unless ['small', 'medium', 'large'].include?(normalized_size)
      return nil
    end

    car = { plate: license_plate_no.to_s, size: normalized_size }

    case normalized_size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << car
        @small -= 1
        return "car with license plate no. #{car[:plate]} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        return "car with license plate no. #{car[:plate]} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        return "car with license plate no. #{car[:plate]} is parked at large"
      else
        return "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        return "car with license plate no. #{car[:plate]} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        return "car with license plate no. #{car[:plate]} is parked at large"
      else
        return shuffle_medium(car)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        return "car with license plate no. #{car[:plate]} is parked at large"
      else
        return shuffle_large(car)
      end
    end

    "No space available"
  end

  def exit_car(license_plate_no)
    normalized_plate = license_plate_no.to_s

    car = @parking_spots[:small_spot].detect { |c| c[:plate] == normalized_plate }
    if car
      @parking_spots[:small_spot].delete(car)
      @small += 1
      return "car with license plate no. #{car[:plate]} exited"
    end

    car = @parking_spots[:medium_spot].detect { |c| c[:plate] == normalized_plate }
    if car
      @parking_spots[:medium_spot].delete(car)
      @medium += 1
      return "car with license plate no. #{car[:plate]} exited"
    end

    car = @parking_spots[:large_spot].detect { |c| c[:plate] == normalized_plate }
    if car
      @parking_spots[:large_spot].delete(car)
      @large += 1
      return "car with license plate no. #{car[:plate]} exited"
    end

    "car with license plate no. #{normalized_plate} exited"
  end

  def shuffle_medium(car)
    # Try to find a medium car in medium or large spots to swap
    # Actually, the requirement says medium cars can use medium or large.
    # If no space, we might try to shuffle a medium car from a medium spot to a large spot?
    # But large spots are occupied by large cars usually.
    # The logic in the broken code tries to move a victim.
    # Let's implement a simple shuffle: find any car in medium spots, move to large? No, large spots might be full.
    # Find any car in medium spots, move to large spots?
    
    # Let's look for a car in medium_spot to move to large_spot
    victim = @parking_spots[:medium_spot].first
    
    if victim && @large > 0
      @parking_spots[:medium_spot].delete(victim)
      @parking_spots[:large_spot] << victim
      # Now we have an empty medium spot for our new car
      @parking_spots[:medium_spot] << car
      @medium -= 1
      return "car with license plate no. #{car[:plate]} is parked at medium"
    end
    
    # If we can't shuffle, just return no space
    "No space available"
  end

  def shuffle_large(car)
    # Large cars can only use large spots.
    # If no space, check if we can shuffle a medium or small car from large spot?
    # But large spots should only contain large cars ideally, unless shuffling happened.
    # The broken code looked for a medium car in large_spot.
    
    victim = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    
    if victim && @medium > 0
      @parking_spots[:large_spot].delete(victim)
      @parking_spots[:medium_spot] << victim
      # Now we have an empty large spot
      @parking_spots[:large_spot] << car
      return "car with license plate no. #{car[:plate]} is parked at large"
    end
    
    "No space available"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = "TK-#{SecureRandom.uuid}"
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    diff = Time.now - entry_time
    diff / 3600.0
  end

  def valid?
    duration_hours < 24.0
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

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || duration_hours < 0
    return 0.0 if duration_hours <= GRACE_PERIOD_HOURS

    normalized_size = car_size.to_s.downcase
    
    # Round up to next full hour
    billable_hours = duration_hours.ceil
    
    rate = RATES[normalized_size] || 0.0
    total = billable_hours * rate
    
    max = MAX_FEE[normalized_size] || Float::INFINITY
    
    total = total < 0 ? 0.0 : total
    max = max < 0 ? Float::INFINITY : max
    
    (total > max ? max : total).to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    # Validation
    if plate.nil? || plate.to_s.strip.empty?
      return { success: false, message: "Invalid license plate", ticket: nil }
    end
    
    normalized_size = size.to_s.strip.downcase
    unless ['small', 'medium', 'large'].include?(normalized_size)
      return { success: false, message: "Invalid car size", ticket: nil }
    end

    message = @garage.admit_car(plate, normalized_size)

    if message && message != "No space available"
      ticket = ParkingTicket.new(plate, normalized_size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message || "No space available", ticket: nil }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tix_in_flight[plate_str]
    
    unless ticket && ticket.valid?
      # Even if invalid, we might still allow exit but charge fee or return error?
      # Requirements say "Validate tickets (expire after 24 hours)".
      # If expired, usually you still pay, but let's return success for the exit action itself as per typical logic, 
      # but maybe flag it. The example shows returning fee.
      # Let's proceed with fee calculation even if ticket is old, but ensure it's not nil
      return { success: false, message: "Ticket not found", fee: 0.0, duration_hours: 0.0 } if ticket.nil?
    end

    @garage.exit_car(plate)
    
    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    @tix_in_flight.delete(plate_str)
    
    { success: true, message: "car with license plate no. #{plate} exited", fee: fee, duration_hours: ticket.duration_hours }
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
    @tix_in_flight[plate.to_s]
  end
end