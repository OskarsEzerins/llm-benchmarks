require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small:   [],
      medium:  [],
      large:   []
    }
  end

  # Returns a string message for success or "No space available"
  def admit_car(license_plate_no, car_size)
    plate = (license_plate_no || '').to_s.strip
    size  = (car_size || '').to_s.downcase

    return "No space available" if plate.empty?
    return "No space available" unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        return "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return "No space available"
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        # Attempt shuffling (optional, not really implemented)
        return "No space available"
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        # Can try shuffling but out of spec
        return "No space available"
      end
    else
      return "No space available"
    end
  end

  # Returns a string message for exit or "No car found"
  def exit_car(license_plate_no)
    plate = (license_plate_no || '').to_s.strip
    found = false

    # small
    car = @parking_spots[:small].find { |c| c[:plate] == plate }
    if car
      @parking_spots[:small].delete(car)
      @small += 1
      found = true
    else
      car = @parking_spots[:medium].find { |c| c[:plate] == plate }
      if car
        @parking_spots[:medium].delete(car)
        @medium += 1
        found = true
      else
        car = @parking_spots[:large].find { |c| c[:plate] == plate }
        if car
          @parking_spots[:large].delete(car)
          @large += 1
          found = true
        end
      end
    end
    if found
      "car with license plate no. #{plate} exited"
    else
      "No car found"
    end
  end

  def available_spots
    {
      small: @small,
      medium: @medium,
      large: @large
    }
  end

  def occupied_count
    @parking_spots[:small].size + @parking_spots[:medium].size + @parking_spots[:large].size
  end

  def total_spots
    @small + @medium + @large + occupied_count
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = (license_plate || '').to_s.strip
    @car_size      = (car_size || '').to_s.downcase
    @entry_time    = entry_time
  end

  # Duration in hours (float)
  def duration_hours
    ((Time.now - @entry_time) / 3600.0)
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

  GRACE_PERIOD_HOURS = 0.25 # 15 minutes

  def calculate_fee(car_size, duration_hours)
    size = (car_size || '').to_s.downcase
    hours = duration_hours.to_f

    return 0.0 if !%w[small medium large].include?(size)
    return 0.0 if hours < 0

    return 0.0 if hours <= GRACE_PERIOD_HOURS

    rate = RATES[size]
    max_fee = MAX_FEE[size]

    billable_hours = (hours - GRACE_PERIOD_HOURS)
    total_hours_ceil = billable_hours.ceil
    total_fee = total_hours_ceil * rate

    total_fee = max_fee if total_fee > max_fee
    total_fee.round(2)
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets        = {}
  end

  # Returns { success: true/false, message: String, ticket: ParkingTicket (if success) }
  def admit_car(plate, size)
    plate_str = (plate || '').to_s.strip
    size_str  = (size || '').to_s.downcase

    unless %w[small medium large].include?(size_str) && !plate_str.empty?
      return { success: false, message: "Invalid input" }
    end

    verdict = @garage.admit_car(plate_str, size_str)
    if verdict =~ /parked at/
      ticket = ParkingTicket.new(plate_str, size_str)
      @tickets[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  # Returns { success: true/false, message: String, fee: Float, duration_hours: Float }
  def exit_car(plate)
    plate_str = (plate || '').to_s.strip
    ticket = @tickets[plate_str]
    garage_msg = @garage.exit_car(plate_str)

    unless ticket
      return { success: false, message: "No active ticket found for #{plate_str}" }
    end

    duration = ticket.duration_hours
    size = ticket.car_size
    fee = @fee_calculator.calculate_fee(size, duration)

    @tickets.delete(plate_str)
    { success: true, message: garage_msg, fee: fee, duration_hours: duration.round(2) }
  end

  # Returns:
  # { small_available: int, medium_available: int, large_available: int, total_occupied: int, total_available: int }
  def garage_status
    avail = @garage.available_spots
    {
      small_available: avail[:small],
      medium_available: avail[:medium],
      large_available: avail[:large],
      total_occupied: @garage.occupied_count,
      total_available: avail[:small] + avail[:medium] + avail[:large]
    }
  end

  def find_ticket(plate)
    plate_str = (plate || '').to_s.strip
    @tickets[plate_str]
  end
end