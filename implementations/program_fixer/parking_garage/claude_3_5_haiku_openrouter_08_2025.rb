require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      tiny_spot:   [],
      mid_spot:    [],
      grande_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return parking_status unless ['small', 'medium', 'large'].include?(car_size.downcase)
    
    kar = { plate: license_plate_no.to_s, size: car_size.downcase }

    case car_size.downcase
    when 'small'
      if @small > 0
        @parking_spots[:tiny_spot] << kar
        @small -= 1
        return parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        return parking_status(kar, 'large')
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        return parking_status(kar, 'large')
      end

    when 'large'
      if @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        return parking_status(kar, 'large')
      end
    end

    parking_status
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    small_car  = @parking_spots[:tiny_spot].detect { |c| c[:plate] == plate }
    medium_car = @parking_spots[:mid_spot].find { |c| c[:plate] == plate }
    large_car  = @parking_spots[:grande_spot].find { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:tiny_spot].delete(small_car)
      @small += 1
      return exit_status(plate)
    elsif medium_car
      @parking_spots[:mid_spot].delete(medium_car)
      @medium += 1
      return exit_status(plate)
    elsif large_car
      @parking_spots[:grande_spot].delete(large_car)
      @large += 1
      return exit_status(plate)
    end

    exit_status
  end

  def parking_status(car = nil, space = nil)
    return "🚗  #{car[:plate]} parked @ #{space}" if car && space
    '¯\_(ツ)_/¯'
  end

  def exit_status(plate = nil)
    plate ? "👋 #{plate} left" : 'Ghost car?'
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate
    @car_size = car_size.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
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
  }

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= 0.25
    car_size = car_size.downcase
    hours = (duration_hours - 0.25).ceil
    rate = RATES[car_size] || 0.0
    total = [hours * rate, MAX_FEE[car_size] || 999.0].min
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

    if result.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
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
      total_occupied: total_spots - (@garage.small + @garage.medium + @garage.large),
      total_available: total_spots
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate]
  end

  private

  def total_spots
    @total_spots ||= @garage.small + @garage.medium + @garage.large
  end
end