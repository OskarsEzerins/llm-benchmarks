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
    kar = { plate: license_plate_no.to_s, size: car_size.to_s.downcase }

    case car_size.to_s.downcase
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
        parking_status
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
    plate = license_plate_no.to_s
    small_car  = @parking_spots[:small].detect { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium].detect { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large].detect { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      exit_status(plate)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      exit_status(plate)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      exit_status(plate)
    else
      exit_status
    end
  end

  def shuffle_medium(kar)
    victim = (@parking_spots[:medium] + @parking_spots[:large]).sample
    return parking_status unless victim

    where = @parking_spots.key(victim) || :medium
    @parking_spots[where].delete(victim)
    @parking_spots[:small] << victim
    @small -= 1
    @parking_spots[where] << kar
    parking_status(kar, where.to_s)
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if first_medium && @medium >= 0
      @parking_spots[:large].delete(first_medium)
      @parking_spots[:medium] << first_medium
      @parking_spots[:large] << kar
      @medium -= 0
      parking_status(kar, 'large')
    end
    parking_status
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : "Ghost car?"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license       = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
  end
end

class ParkingFeeCalculator
  RATES = {
    small:  2.0,
    medium: 3.0,
    large:  5.0
  }

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours < 0
    
    size = car_size.to_s.downcase
    return 0.0 unless ['small', 'medium', 'large'].include?(size)
    
    effective_hours = duration_hours - 0.25
    return 0.0 if effective_hours <= 0
    
    hours_to_charge = effective_hours.ceil
    rate = RATES[size.to_sym] || 0.0
    total = hours_to_charge * rate
    
    max_fee = MAX_FEE[size] || Float::INFINITY
    [total, max_fee].min
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets_in_flight = {}
  end

  def admit_car(plate, size)
    size_normalized = validate_and_normalize_size(size)
    return { success: false, message: "Invalid car size" } unless size_normalized
    
    plate_normalized = plate.to_s.strip
    return { success: false, message: "Invalid license plate" } if plate_normalized.empty?
    
    verdict = @garage.admit_car(plate_normalized, size_normalized)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate_normalized, size_normalized)
      @tickets_in_flight[plate_normalized] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_normalized = plate.to_s
    ticket = @tickets_in_flight[plate_normalized]
    return { success: false, message: "No ticket found for this car" } unless ticket
    
    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_normalized)

    @tickets_in_flight.delete(plate_normalized)
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

  private

  def validate_and_normalize_size(size)
    return nil if size.nil?
    normalized = size.to_s.downcase.strip
    return normalized if ['small', 'medium', 'large'].include?(normalized)
    nil
  end
end