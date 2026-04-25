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
    # Input validation
    license_plate_no = license_plate_no.to_s.strip
    return "No space available" if license_plate_no.empty?
    
    car_size = car_size.to_s.downcase.strip
    return "No space available" unless ['small', 'medium', 'large'].include?(car_size)

    kar = { plate: license_plate_no, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s.strip
    
    small_car  = @parking_spots[:small].detect { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium].find   { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:large].find { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      exit_status(license_plate_no)
    else
      "No space available"
    end
  end

  def shuffle_medium(kar)
    # Try to move a small car from medium to small to free up medium spot? 
    # Or move a small car from medium to large? No, small prefers small.
    # Standard shuffling: If medium is full, can we move a small car from a medium spot to a small spot?
    # But small spots are likely full if we are here.
    # Let's look for a small car in a medium spot and move it to a small spot if available.
    if @small > 0
      victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if victim
        @parking_spots[:medium].delete(victim)
        @parking_spots[:small] << victim
        @small -= 1
        @medium += 1 # Freed up a medium spot
        
        @parking_spots[:medium] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      end
    end
    
    # If no small car in medium to shuffle, check if we can put in large
    if @large > 0
      @parking_spots[:large] << kar
      @large -= 1
      return parking_status(kar, 'large')
    end

    "No space available"
  end

  def shuffle_large(kar)
    # Large car needs large spot. All large spots full.
    # Can we shuffle? Move a medium car from large spot to medium spot?
    first_medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    
    if first_medium_in_large && @medium > 0
      @parking_spots[:large].delete(first_medium_in_large)
      @parking_spots[:medium] << first_medium_in_large
      @medium -= 1
      @large += 1 # Freed up a large spot
      
      @parking_spots[:large] << kar
      @large -= 1
      return parking_status(kar, 'large')
    end
    
    # Can we move a small car from large spot to medium/small?
    first_small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if first_small_in_large
      # Try to move to medium first
      if @medium > 0
        @parking_spots[:large].delete(first_small_in_large)
        @parking_spots[:medium] << first_small_in_large
        @medium -= 1
        @large += 1
        
        @parking_spots[:large] << kar
        @large -= 1
        return parking_status(kar, 'large')
      elsif @small > 0
         @parking_spots[:large].delete(first_small_in_large)
         @parking_spots[:small] << first_small_in_large
         @small -= 1
         @large += 1
         
         @parking_spots[:large] << kar
         @large -= 1
         return parking_status(kar, 'large')
      end
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
    if plate && !plate.empty?
      "car with license plate no. #{plate} exited"
    else
      "No space available"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
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
    car_size = car_size.to_s.downcase.strip
    duration_hours = duration_hours.to_f
    
    return 0.0 if duration_hours < 0
    return 0.0 unless RATES.key?(car_size)

    # Grace period: first 15 minutes (0.25 hours) free
    if duration_hours <= 0.25
      return 0.0
    end

    # Round up partial hours to next full hour
    hours = duration_hours.ceil
    
    rate  = RATES[car_size]
    total = hours * rate
    
    max_fee = MAX_FEE[car_size]
    [total, max_fee].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @tix_in_flight   = {}
  end

  def admit_car(plate, size)
    # Normalize inputs
    plate_str = plate.to_s.strip
    size_str = size.to_s.downcase.strip
    
    # Validate inputs before attempting admission
    if plate_str.empty? || !['small', 'medium', 'large'].include?(size_str)
       return { success: false, message: "No space available", ticket: nil }
    end

    verdict = @garage.admit_car(plate, size)

    if verdict.include?("is parked at")
      ticket               = ParkingTicket.new(plate, size)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict, ticket: nil }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    
    ticket = @tix_in_flight[plate_str]
    
    # Even if we don't have a ticket, we might need to try exiting from garage 
    # but fee calculation requires ticket info. 
    # If no ticket found, we can't calculate fee properly.
    if ticket.nil?
       # Try to exit from garage anyway? The prompt implies tracking via tickets.
       # Let's assume if no ticket, we can't process exit with fee.
       # However, to be robust, let's check if the car is actually in the garage.
       # But without ticket, we don't know size for fee.
       return { success: false, message: "No space available", fee: 0.0, duration_hours: 0.0 }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate_str)
    
    success = result.include?("exited")
    
    { success: success, message: result, fee: fee, duration_hours: ticket.duration_hours }
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
    @tix_in_flight.fetch(plate.to_s.strip, nil)
  end
end