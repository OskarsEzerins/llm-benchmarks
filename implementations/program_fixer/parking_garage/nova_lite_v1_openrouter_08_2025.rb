require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @parking_spots = {
      small:   [],
      medium:  [],
      large:   []
    }
  end

  def admit_car(license_plate_no, car_size)
    license_plate_no = license_plate_no.to_s.strip.downcase
    return "Invalid license plate" if license_plate_no.empty?
    
    car_size = car_size.to_s.strip.downcase
    return "Invalid car size" unless %w[small medium large].include?(car_size)

    car = { plate: license_plate_no, size: car_size }

    case car_size
    when 'small'
      if @small.positive?
        @parking_spots[:small] << car
        @small -= 1
        return parking_status(car, 'small')
      elsif @medium.positive?
        @parking_spots[:medium] << car
        @medium -= 1
        return parking_status(car, 'medium')
      elsif @large.positive?
        if @parking_spots[:medium].any? || @parking_spots[:large].any?
          shuffle_medium(car)
        else
          @parking_spots[:large] << car
          @large -= 1
          return parking_status(car, 'large')
        end
      end
    when 'medium'
      if @medium.positive?
        @parking_spots[:medium] << car
        @medium -= 1
        return parking_status(car, 'medium')
      elsif @large.positive?
        @parking_spots[:large] << car
        @large -= 1
        return parking_status(car, 'large')
      end
    when 'large'
      if @large.positive?
        @parking_spots[:large] << car
        @large -= 1
        return parking_status(car, 'large')
      end
    end

    "No space available"
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s.strip.downcase
    return "Invalid license plate" if license_plate_no.empty?

    spot = @parking_spots[:small].find { |car| car[:plate] == license_plate_no }
    if spot
      @parking_spots[:small].delete(spot)
      @small += 1
      return exit_status(license_plate_no)
    end

    spot = @parking_spots[:medium].find { |car| car[:plate] == license_plate_no }
    if spot
      @parking_spots[:medium].delete(spot)
      @medium += 1
      return exit_status(license_plate_no)
    end

    spot = @parking_spots[:large].find { |car| car[:plate] == license_plate_no }
    if spot
      @parking_spots[:large].delete(spot)
      @large += 1
      return exit_status(license_plate_no)
    end

    "Car not found"
  end

  def shuffle_medium(car)
    victim = @parking_spots[:medium].find { |c| c[:size] == 'medium' } || @parking_spots[:large].find { |c| c[:size] == 'medium' }
    return "No space available" unless victim

    where = victim[:size] == 'medium' ? :medium : :large
    @parking_spots[where].delete(victim)
    @parking_spots[:small] << victim
    @small -= 1

    @parking_spots[where] << car
    if where == :medium
      @medium -= 1
    else
      @large -= 1
    end

    parking_status(car, where.to_s.sub('_spot', ''))
  end

  def parking_status(car, space)
    "Car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate)
    "Car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate
    @car_size = car_size
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = {
    small: 2.0,
    medium: 3.0,
    large: 5.0
  }.freeze

  MAX_FEES = {
    small: 20.0,
    medium: 30.0,
    large: 50.0
  }.freeze

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= GRACE_PERIOD

    duration_hours = [duration_hours - GRACE_PERIOD, 0.0].max
    hours = duration_hours.ceil
    rate = RATES[car_size.to_sym]
    total = hours * rate
    [total, MAX_FEES[car_size.to_sym]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(license_plate, car_size)
    result = @garage.admit_car(license_plate, car_size)
    return result unless result.start_with?("Car with license")

    ticket = ParkingTicket.new(license_plate, car_size)
    @tickets[license_plate] = ticket
    { success: true, message: result, ticket: ticket }
  end

  def exit_car(license_plate)
    ticket = @tickets.delete(license_plate)
    return { success: false, message: "Car not found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(license_plate)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(license_plate)
    @tickets[license_plate]
  end

  private

  def total_occupied
    @parking_spots[:small].size + @parking_spots[:medium].size + @parking_spots[:large].size
  end

  def total_available
    @garage.small + @garage.medium + @garage.large - total_occupied
  end
end