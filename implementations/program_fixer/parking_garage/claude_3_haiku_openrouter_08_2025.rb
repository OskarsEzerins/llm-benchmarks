require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

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
    car = { plate: license_plate_no, size: car_size.downcase }

    case car[:size]
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
        parking_status
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
    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    car = @parking_spots.values.flatten.find { |c| c[:plate] == license_plate_no }
    return exit_status if car.nil?

    spot_type = @parking_spots.key(car)
    @parking_spots[spot_type].delete(car)
    increment_available_spots(spot_type)
    exit_status(license_plate_no)
  end

  def shuffle_medium(car)
    victim = (@parking_spots[:medium] + @parking_spots[:large]).sample
    return parking_status unless victim

    where = @parking_spots.key(victim) || :medium
    @parking_spots[where].delete(victim)
    @parking_spots[:small] << victim
    increment_available_spots(where)
    @parking_spots[where] << car
    parking_status(car, where)
  end

  def shuffle_large(car)
    first_medium = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large].delete(first_medium)
      @parking_spots[:medium] << first_medium
      @parking_spots[:large] << car
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
    plate ? "car with license plate no. #{plate} exited" : "Ghost car?"
  end

  private

  def increment_available_spots(spot_type)
    case spot_type
    when :small
      @small += 1
    when :medium
      @medium += 1
    when :large
      @large += 1
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.downcase
    @entry_time    = entry_time
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
    rate = RATES[car_size.to_sym] || RATES[:small]
    [hours * rate, MAX_FEE[car_size] || 999.0].min
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @tickets_in_use  = {}
  end

  def admit_car(license_plate, car_size)
    result = @garage.admit_car(license_plate, car_size)
    if result.include?("is parked")
      ticket = ParkingTicket.new(license_plate, car_size)
      @tickets_in_use[license_plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(license_plate)
    ticket = @tickets_in_use[license_plate]
    return { success: false, message: "No ticket found for #{license_plate}" } if ticket.nil?

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(license_plate)
    @tickets_in_use.delete(license_plate)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @tickets_in_use.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(license_plate)
    @tickets_in_use[license_plate]
  end
end