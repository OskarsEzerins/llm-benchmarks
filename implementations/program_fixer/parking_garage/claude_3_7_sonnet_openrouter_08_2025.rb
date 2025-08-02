require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

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
    return "No space available" unless license_plate_no && car_size
    license_plate_no = license_plate_no.to_s.strip
    return "No space available" if license_plate_no.empty?
    
    car_size = car_size.to_s.downcase.strip
    unless ['small', 'medium', 'large'].include?(car_size)
      return "No space available"
    end
    
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
    return "No car found" unless license_plate_no
    license_plate_no = license_plate_no.to_s.strip
    
    small_car  = @parking_spots[:small].detect { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == license_plate_no }
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
      exit_status
    end
  end

  def shuffle_medium(kar)
    victim = @parking_spots[:medium].sample || @parking_spots[:large].sample
    return parking_status unless victim

    where = @parking_spots.key(@parking_spots.values.find { |spots| spots.include?(victim) })
    @parking_spots[where].delete(victim)
    @parking_spots[:small] << victim if @small > 0
    @small -= 1 if @small > 0
    @parking_spots[where] << kar
    parking_status(kar, where.to_s)
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large].delete(first_medium)
      @parking_spots[:medium] << first_medium
      @parking_spots[:large] << kar
      @medium -= 1
      return parking_status(kar, 'large')
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
    plate ? "car with license plate no. #{plate} exited" : "No car found"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    (Time.now - entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid[0..7]}"
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
    return 0.0 if duration_hours.nil? || duration_hours < 0
    
    car_size = car_size.to_s.downcase
    rate = RATES[car_size] || RATES['small']
    max = MAX_FEE[car_size] || MAX_FEE['small']
    
    # Grace period
    return 0.0 if duration_hours <= 0.25
    
    # Round up to the next hour
    hours = duration_hours.ceil
    total = hours * rate
    
    # Cap at maximum
    [total, max].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate = plate.to_s
    ticket = @tix_in_flight[plate]
    return { success: false, message: 'No ticket found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
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