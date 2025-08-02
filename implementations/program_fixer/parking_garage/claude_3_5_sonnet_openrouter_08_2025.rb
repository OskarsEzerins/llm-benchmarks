require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i 
    @large = large.to_i

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    car = { plate: license_plate_no.to_s, size: car_size.to_s.downcase }

    case car[:size]
    when 'small'
      if @small.positive?
        @parking_spots[:small_spot] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium.positive?
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large.positive?
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end

    when 'medium'
      if @medium.positive?
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large.positive?
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_medium(car)
      end

    when 'large'
      if @large.positive?
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    small_car = @parking_spots[:small_spot].detect { |c| c[:plate] == license_plate_no.to_s }
    medium_car = @parking_spots[:medium_spot].find { |c| c[:plate] == license_plate_no.to_s }
    large_car = @parking_spots[:large_spot].find { |c| c[:plate] == license_plate_no.to_s }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      exit_status(license_plate_no)
    else
      exit_status
    end
  end

  def shuffle_medium(car)
    victim = (@parking_spots[:medium_spot] + @parking_spots[:large_spot]).sample
    return parking_status unless victim

    where = @parking_spots.key(victim)
    @parking_spots[where].delete(victim)
    @parking_spots[:small_spot] << victim
    @small -= 1
    @parking_spots[where] << car
    parking_status(car, where.to_s.sub('_spot', ''))
  end

  def shuffle_large(car)
    first_medium = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium.positive?
      @parking_spots[:large_spot].delete(first_medium)
      @parking_spots[:medium_spot] << first_medium
      @parking_spots[:large_spot] << car
      @medium -= 1
      parking_status(car, 'large')
    else
      parking_status
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
    plate ? "car with license plate no. #{plate} exited" : "Car not found"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = {
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= 0.25
    return 0.0 if duration_hours < 0

    hours = duration_hours.ceil
    rate = RATES[car_size.to_s.downcase] || RATES['large']
    total = hours * rate
    [total, MAX_FEE[car_size.to_s.downcase] || MAX_FEE['large']].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid input" } if plate.nil? || size.nil?
    
    verdict = @garage.admit_car(plate, size)

    if verdict.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    ticket = @tix_in_flight[plate.to_s]
    return { success: false, message: 'Ticket not found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate.to_s)
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