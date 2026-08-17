require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

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
    plate = license_plate_no.to_s.strip
    size  = car_size.to_s.downcase.strip

    return "No space available" if plate.empty?
    return "No space available" unless %w[small medium large].include?(size)

    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip

    small_car  = @parking_spots[:small_spot].detect  { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium_spot].find   { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large_spot].find    { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      exit_status(plate)
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      exit_status(plate)
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      exit_status(plate)
    else
      "Car not found"
    end
  end

  def shuffle_medium(kar)
    if @small > 0
      victim = nil
      victim_spot = nil

      @parking_spots[:medium_spot].each do |c|
        if c[:size] == 'small'
          victim = c
          victim_spot = :medium_spot
          break
        end
      end

      if victim.nil?
        @parking_spots[:large_spot].each do |c|
          if c[:size] == 'small'
            victim = c
            victim_spot = :large_spot
            break
          end
        end
      end

      if victim
        @parking_spots[victim_spot].delete(victim)
        @parking_spots[:small_spot] << victim
        @small -= 1
        @parking_spots[victim_spot] << kar
        spot_name = victim_spot == :medium_spot ? 'medium' : 'large'
        parking_status(kar, spot_name)
      else
        "No space available"
      end
    else
      "No space available"
    end
  end

  def shuffle_large(kar)
    if @medium > 0
      victim = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
      if victim
        @parking_spots[:large_spot].delete(victim)
        @parking_spots[:medium_spot] << victim
        @medium -= 1
        @parking_spots[:large_spot] << kar
        parking_status(kar, 'large')
      else
        "No space available"
      end
    else
      "No space available"
    end
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
      "Car not found"
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
    ((Time.now - @entry_time) / 3600.0).round(1)
  end

  def valid?
    (Time.now - @entry_time) / 3600.0 < 24
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
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours < 0
    return 0.0 if duration_hours <= 0.25

    hours = duration_hours.ceil
    rate  = RATES[size]
    total = (hours * rate).to_f
    [total, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str  = size.to_s.downcase.strip

    if plate_str.empty? || !%w[small medium large].include?(size_str)
      return { success: false, message: "No space available" }
    end

    message = @garage.admit_car(plate_str, size_str)

    if message.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @active_tickets[plate_str] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @active_tickets[plate_str]

    unless ticket
      return { success: false, message: "No active ticket found" }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)

    @active_tickets.delete(plate_str)
    { success: true, message: result, fee: fee.to_f, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @active_tickets.size,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    plate_str = plate.to_s.strip
    @active_tickets[plate_str]
  end
end