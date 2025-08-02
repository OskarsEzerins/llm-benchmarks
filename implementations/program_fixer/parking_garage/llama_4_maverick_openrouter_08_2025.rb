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
    car_size = car_size.downcase
    return parking_status unless ['small', 'medium', 'large'].include?(car_size)

    kar = { plate: license_plate_no.to_s, size: car_size }

    case car_size
    when 'small'
      if @small.positive?
        @parking_spots[:small] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium.positive?
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large.positive?
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end

    when 'medium'
      if @medium.positive?
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large.positive?
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end

    when 'large'
      if @large.positive?
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s
    small_car  = @parking_spots[:small].detect { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium].detect { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:large].detect { |c| c[:plate] == license_plate_no }

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
    return parking_status unless @large.positive?

    @parking_spots[:large] << kar
    @large -= 1
    parking_status(kar, 'large')
  end

  def shuffle_large(kar)
    medium_car = @parking_spots[:large].detect { |c| c[:size] == 'medium' }
    if medium_car && @medium.positive?
      @parking_spots[:large].delete(medium_car)
      @parking_spots[:medium] << medium_car
      @medium -= 1
      @large += 1
      @parking_spots[:large] << kar
      @large -= 1
      parking_status(kar, 'large')
    else
      parking_status
    end
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : 'car not found'
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id           = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size     = car_size.downcase
    @entry_time   = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(1)
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
    return 0.0 if duration_hours <= 0.25

    hours = (duration_hours - 0.25).ceil
    rate  = RATES[car_size.downcase.to_sym]
    total = hours * rate
    [total, MAX_FEE[car_size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    return { success: false, message: 'Invalid car size' } unless ['small', 'medium', 'large'].include?(size.downcase)
    return { success: false, message: 'Invalid license plate' } if plate.to_s.strip.empty?

    verdict = @garage.admit_car(plate, size)

    if verdict.include?('parked')
      ticket               = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate = plate.to_s
    ticket = @tix_in_flight[plate]
    return { success: false, message: 'Ticket not found' } unless ticket

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
      total_occupied: (@garage.small + @garage.medium + @garage.large) - (@garage.parking_spots[:small].size + @garage.parking_spots[:medium].size + @garage.parking_spots[:large].size),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end
end