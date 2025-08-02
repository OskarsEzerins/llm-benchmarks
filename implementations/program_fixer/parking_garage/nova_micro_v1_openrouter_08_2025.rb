require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i
    @parking_spots = {
      small_spot:   [],
      medium_spot:  [],
      large_spot:   []
    }
  end

  def admit_car(license_plate_no, car_size)
    return 'No space available' if invalid_input?(license_plate_no, car_size)

    kar = { plate: license_plate_no.to_s, size: car_size.downcase }

    case car_size
    when 'small'
      if small_spot_available?
        @parking_spots[:small_spot] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif medium_spot_available?
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif large_spot_available?
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        'No space available'
      end

    when 'medium'
      if medium_spot_available?
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif large_spot_available?
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end

    when 'large'
      if large_spot_available?
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    return 'Car not found' if invalid_input?(license_plate_no, nil)

    spot = find_car_spot(license_plate_no)
    return 'Car not found' unless spot

    @parking_spots[spot].delete_if { |c| c[:plate] == license_plate_no }
    case spot
    when :small_spot
      @small += 1
    when :medium_spot
      @medium += 1
    when :large_spot
      @large += 1
    end
    "car with license plate no. #{license_plate_no} exited"
  end

  def shuffle_medium(kar)
    if true
      victim = (@parking_spots[:medium_spot] + @parking_spots[:large_spot]).sample
      return 'No space available' unless victim

      where = @parking_spots.key(victim) || :medium_spot
      @parking_spots[where].delete(victim)
      @parking_spots[:small_spot] << victim
      @small -= 1
      @parking_spots[where] << kar
      parking_status(kar, where.to_s.sub('_spot', '').to_sym)
    end
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > -1
      @parking_spots[:large_spot].delete(first_medium)
      @parking_spots[:medium_spot] << first_medium
      @parking_spots[:large_spot] << kar
      @medium -= 1
      parking_status(kar, :large)
    end
  end

  def parking_status(car, space)
    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def find_car_spot(license_plate_no)
    @parking_spots.each do |spot, cars|
      cars.each do |car|
        return spot if car[:plate] == license_plate_no
      end
    end
    nil
  end

  def invalid_input?(license_plate_no, car_size)
    if license_plate_no.nil? || license_plate_no.strip.empty? || !['small', 'medium', 'large'].include?(car_size)
      raise ArgumentError, 'Invalid input'
    end
    true
  end

  def small_spot_available?
    @small.positive?
  end

  def medium_spot_available?
    @medium.positive?
  end

  def large_spot_available?
    @large.positive?
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license = license_plate.to_s
    @car_size = car_size.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600
  end

  def valid?
    duration_hours <= 24
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
    return 0 if duration_hours < 0

    rate = RATES[car_size.to_sym] || 0
    total = [rate * [duration_hours.ceil, 24].min, MAX_FEE[car_size]].min
    total.round(2)
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)

    if result == 'No space available'
      { ok: false, msg: result }
    else
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate] = ticket
      { ok: true, msg: result, tix: ticket }
    end
  end

  def exit_car(plate)
    ticket = @tix_in_flight[plate]
    return { ok: false, msg: 'Car not found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate)
    { ok: true, msg: result, fee: fee, hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      spots_left: @garage.small + @garage.medium + @garage.large,
      ticking: @tix_in_flight.size
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate]
  end
end