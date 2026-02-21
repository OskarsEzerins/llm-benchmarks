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

  def admit_car(license_plate, car_size)
    plate = license_plate.to_s
    size  = car_size.to_s.downcase
    return "Invalid car size: #{size}" unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        park_car(car, :small)
      elsif @medium > 0
        park_car(car, :medium)
      elsif @large > 0
        park_car(car, :large)
      else
        parking_status() # No space
      end

    when 'medium'
      if @medium > 0
        park_car(car, :medium)
      elsif @large > 0
        park_car(car, :large)
      else
        parking_status() # No space
      end

    when 'large'
      if @large > 0
        park_car(car, :large)
      else
        if shuffle_large(car)
          parking_status(car, 'large')
        else
          parking_status() # No space
        end
      end
    end
  end

  def exit_car(license_plate)
    plate = license_plate.to_s
    @parking_spots.each do |type, cars|
      car = cars.find { |c| c[:plate] == plate }
      if car
        cars.delete(car)
        increment_spots(type)
        return exit_status(plate)
      end
    end
    exit_status() # not found
  end

  private

  def park_car(car, spot_type)
    @parking_spots[spot_type] << car
    decrement_spots(spot_type)
    parking_status(car, spot_type.to_s)
  end

  def decrement_spots(spot_type)
    case spot_type
    when :small  then @small  -= 1
    when :medium then @medium -= 1
    when :large  then @large  -= 1
    end
  end

  def increment_spots(spot_type)
    case spot_type
    when :small  then @small  += 1
    when :medium then @medium += 1
    when :large  then @large  += 1
    end
  end

  def parking_status(car = nil, spot_type = nil)
    if car && spot_type
      "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      "Car with license plate #{plate} not found"
    end
  end

  def shuffle_large(new_large_car)
    # Find a medium car occupying a large spot
    medium_car_index = @parking_spots[:large].find_index { |car| car[:size] == 'medium' }
    return false unless medium_car_index && @medium > 0

    medium_car = @parking_spots[:large].delete_at(medium_car_index)
    @parking_spots[:medium] << medium_car
    @medium -= 1   # occupy a medium spot
    @large  += 1   # free the large spot
    @parking_spots[:large] << new_large_car
    @large  -= 1   # occupy the freed large spot
    true
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
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
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  GRACE_PERIOD = 0.25 # 15 minutes in hours

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours < 0

    size = car_size.to_s.downcase
    rate = RATES[size]
    max  = MAX_FEE[size]
    return 0.0 if rate.nil? || max.nil?

    effective = duration_hours - GRACE_PERIOD
    if effective <= 0.0
      0.0
    else
      hours = effective.ceil
      fee   = hours * rate
      fee > max ? max : fee
    end
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :tickets

  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @tickets         = {}
    @total_small     = small_spots
    @total_medium    = medium_spots
    @total_large     = large_spots
  end

  def admit_car(license_plate, car_size)
    plate = license_plate.to_s
    size  = car_size.to_s.downcase

    unless %w[small medium large].include?(size)
      return { success: false, message: "Invalid car size: #{size}" }
    end
    if plate.strip.empty?
      return { success: false, message: "Invalid license plate" }
    end

    result = @garage.admit_car(plate, size)

    if result != "No space available"
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(license_plate)
    plate = license_plate.to_s
    ticket = @tickets[plate]

    unless ticket
      return { success: false, message: "No active ticket for #{plate}" }
    end

    fee    = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    if result.include?("exited")
      @tickets.delete(plate)
      { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
    else
      { success: false, message: result }
    end
  end

  def garage_status
    small_available  = @garage.small
    medium_available = @garage.medium
    large_available  = @garage.large

    total_occupied = (@total_small - small_available) +
                     (@total_medium - medium_available) +
                     (@total_large - large_available)

    total_available = small_available + medium_available + large_available

    {
      small_available:  small_available,
      medium_available: medium_available,
      large_available:  large_available,
      total_occupied:   total_occupied,
      total_available:  total_available
    }
  end

  def find_ticket(license_plate)
    @tickets[license_plate.to_s]
  end
end