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
    # Validate inputs
    return "No space available" if license_plate_no.nil? || license_plate_no.to_s.strip.empty?

    car_size = car_size.to_s.downcase.strip
    return "No space available" unless %w[small medium large].include?(car_size)

    car = { plate: license_plate_no.to_s.strip, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_medium(car)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    plate_str = license_plate_no.to_s

    small_car  = @parking_spots[:small].find  { |c| c[:plate] == plate_str }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate_str }
    large_car  = @parking_spots[:large].find  { |c| c[:plate] == plate_str }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      exit_status(plate_str)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      exit_status(plate_str)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      exit_status(plate_str)
    else
      "car not found"
    end
  end

  private

  def shuffle_medium(car)
    # Need a small spot free; find a small car wrongly parked in medium/large spot
    return "No space available" unless @small > 0

    victim = (@parking_spots[:medium] + @parking_spots[:large]).find { |c| c[:size] == 'small' }
    return "No space available" unless victim

    # find which spot the victim is in
    spot = @parking_spots.find { |_, cars| cars.include?(victim) }.first
    @parking_spots[spot].delete(victim)
    @parking_spots[:small] << victim
    @small -= 1

    @parking_spots[:medium] << car
    # medium count unchanged because we removed victim (freeing a spot) and put car there
    parking_status(car, 'medium')
  end

  def shuffle_large(car)
    return "No space available" unless @medium > 0

    # Find a medium car occupying a large spot
    first_medium = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    return "No space available" unless first_medium

    @parking_spots[:large].delete(first_medium)
    @parking_spots[:medium] << first_medium
    @medium -= 1

    @parking_spots[:large] << car
    # large count unchanged (medium car out, large car in)
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
    @id           = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size     = car_size.to_s.downcase
    @entry_time   = entry_time
  end

  def duration_hours
    (Time.now - entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24
  end

  private

  def generate_ticket_id
    "TK-#{rand(9999)}"
  end
end

class ParkingFeeCalculator
  RATES = {
    small:  2.0,
    medium: 3.0,
    large:  5.0
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  def calculate_fee(car_size, duration_hours)
    # Grace period: first 0.25 hours free
    return 0.0 if duration_hours <= 0.25
    return 0.0 if duration_hours < 0   # handle negative durations gracefully

    hours = duration_hours.ceil
    car_size = car_size.to_s.downcase
    rate = RATES[car_size.to_sym]
    return 0.0 unless rate  # invalid car size -> free

    total = hours * rate
    max = MAX_FEE[car_size] || 999
    [total, max].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @small_capacity  = small_spots.to_i
    @medium_capacity = medium_spots.to_i
    @large_capacity  = large_spots.to_i

    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @active_tickets  = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)

    if verdict.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_key = plate.to_s
    ticket = @active_tickets[plate_key]
    return { success: false, message: 'No active ticket found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @active_tickets.delete(plate_key)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    small_avail = @garage.small
    medium_avail = @garage.medium
    large_avail = @garage.large

    total_available = small_avail + medium_avail + large_avail
    total_capacity = @small_capacity + @medium_capacity + @large_capacity
    total_occupied = total_capacity - total_available

    {
      small_available:  small_avail,
      medium_available: medium_avail,
      large_available:  large_avail,
      total_occupied:   total_occupied,
      total_available:  total_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s]
  end
end