require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

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

  def admit_car(license_plate_no, car_size)
    # Input validation
    return "No space available" if !license_plate_no || license_plate_no.to_s.strip.empty?
    return "No space available" if !car_size || !%w[small medium large].include?(car_size.to_s.downcase)

    car_size = car_size.to_s.downcase
    kar = { plate: license_plate_no.to_s, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        "car with license plate no. #{kar[:plate]} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        "car with license plate no. #{kar[:plate]} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        "car with license plate no. #{kar[:plate]} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        "car with license plate no. #{kar[:plate]} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        "car with license plate no. #{kar[:plate]} is parked at large"
      else
        shuffle_medium(kar)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        "car with license plate no. #{kar[:plate]} is parked at large"
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s if license_plate_no

    small_car  = @parking_spots[:small].detect { |c| c[:plate] == license_plate_no.to_s }
    medium_car = @parking_spots[:medium].find  { |c| c[:plate] == license_plate_no.to_s }
    large_car  = @parking_spots[:large].find   { |c| c[:plate] == license_plate_no.to_s }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      "car with license plate no. #{small_car[:plate]} exited"
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      "car with license plate no. #{medium_car[:plate]} exited"
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      "car with license plate no. #{large_car[:plate]} exited"
    else
      "car not found"
    end
  end

  def shuffle_medium(kar)
    # Find a small car parked in a medium or large spot to move to small
    victim = nil
    source_spot = nil

    # Look in medium spots for any car (preferably small)
    victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
    source_spot = :medium if victim

    # If not found, look in large spots for any car (preferably small)
    unless victim
      victim = @parking_spots[:large].find { |c| c[:size] == 'small' }
      source_spot = :large if victim
    end

    if victim
      @parking_spots[source_spot].delete(victim)
      @parking_spots[:small] << victim
      @small -= 1

      # Park the new car in the spot where victim was
      @parking_spots[source_spot] << kar
      if source_spot == :medium
        @medium -= 1
      else
        @large -= 1
      end
      "car with license plate no. #{kar[:plate]} is parked at #{source_spot}"
    else
      "No space available"
    end
  end

  def shuffle_large(kar)
    # Find a medium car parked in a large spot to move to medium
    first_medium = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large].delete(first_medium)
      @parking_spots[:medium] << first_medium
      @medium -= 1

      @parking_spots[:large] << kar
      @large -= 1
      "car with license plate no. #{kar[:plate]} is parked at large"
    else
      "No space available"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id         = SecureRandom.uuid
    @license_plate      = license_plate.to_s
    @car_size     = car_size.to_s.downcase
    @entry_time   = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(2)
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
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  def calculate_fee(car_size, duration_hours)
    return 0.0 if !duration_hours || duration_hours < 0
    return 0.0 if !car_size || !%w[small medium large].include?(car_size.to_s.downcase)

    car_size = car_size.to_s.downcase
    duration_hours = duration_hours.to_f

    # Grace period: first 15 minutes (0.25 hours) free
    return 0.0 if duration_hours <= 0.25

    # Round up partial hours to next full hour
    hours = duration_hours.ceil.to_f

    rate = RATES[car_size] || 0.0
    total_fee = hours * rate

    # Apply daily maximum
    max = MAX_FEE[car_size] || Float::INFINITY
    [total_fee, max].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots.to_i, medium_spots.to_i, large_spots.to_i)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets_in_flight  = {}
  end

  def admit_car(plate, size)
    # Input validation
    if !plate || plate.to_s.strip.empty? || !size || !%w[small medium large].include?(size.to_s.downcase)
      { success: false, message: "Invalid input" }
    else
      verdict = @garage.admit_car(plate, size)

      if verdict.include?("is parked at")
        ticket = ParkingTicket.new(plate, size)
        @tickets_in_flight[plate.to_s] = ticket
        { success: true, message: verdict, ticket: ticket }
      else
        { success: false, message: verdict }
      end
    end
  end

  def exit_car(plate)
    ticket = @tickets_in_flight[plate.to_s]
    return { success: false, message: 'Ticket not found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate.to_s)

    @tickets_in_flight.delete(plate.to_s)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @tickets_in_flight.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tickets_in_flight[plate.to_s]
  end
end