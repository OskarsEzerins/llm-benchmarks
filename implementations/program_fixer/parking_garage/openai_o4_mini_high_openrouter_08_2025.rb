require 'securerandom'

class ParkingGarage
  def initialize(small, medium, large)
    @capacity = {
      small:  small.to_i,
      medium: medium.to_i,
      large:  large.to_i
    }
    @spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(plate, size)
    case size
    when 'small'
      if available?(:small)
        park(:small, plate, size)
      elsif available?(:medium)
        park(:medium, plate, size)
      elsif available?(:large)
        park(:large, plate, size)
      else
        'No space available'
      end
    when 'medium'
      if available?(:medium)
        park(:medium, plate, size)
      elsif available?(:large)
        park(:large, plate, size)
      else
        'No space available'
      end
    when 'large'
      if available?(:large)
        park(:large, plate, size)
      elsif shuffle_large && available?(:large)
        park(:large, plate, size)
      else
        'No space available'
      end
    else
      'Invalid car size'
    end
  end

  def exit_car(plate)
    plate = plate.to_s
    [:small, :medium, :large].each do |spot|
      car = @spots[spot].find { |c| c[:plate] == plate }
      if car
        @spots[spot].delete(car)
        return "car with license plate no. #{plate} exited"
      end
    end
    'Car not found'
  end

  def small_available
    @capacity[:small] - @spots[:small].size
  end

  def medium_available
    @capacity[:medium] - @spots[:medium].size
  end

  def large_available
    @capacity[:large] - @spots[:large].size
  end

  def total_occupied
    @spots.values.map(&:size).sum
  end

  private

  def available?(spot)
    case spot
    when :small
      small_available > 0
    when :medium
      medium_available > 0
    when :large
      large_available > 0
    else
      false
    end
  end

  def park(spot, plate, size)
    @spots[spot] << { plate: plate, size: size }
    "car with license plate no. #{plate} is parked at #{spot}"
  end

  def shuffle_large
    victim = @spots[:large].find { |c| c[:size] == 'medium' }
    if victim && medium_available > 0
      @spots[:large].delete(victim)
      @spots[:medium] << victim
      true
    else
      false
    end
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    (Time.now - @entry_time) <= 24 * 3600
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    dur = duration_hours.to_f
    return 0.0 if dur <= 0
    return 0.0 if dur <= GRACE_PERIOD
    billable = (dur - GRACE_PERIOD).ceil
    rate = RATES[car_size.to_sym] || 0.0
    fee = billable * rate
    max = MAX_FEE[car_size.to_s.downcase] || fee
    [fee, max].min
  end
end

class ParkingGarageManager
  VALID_SIZES = %w[small medium large]

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    return { success: false, message: 'Invalid license plate' } if plate_str.empty?
    size_str = size.to_s.strip.downcase
    return { success: false, message: 'Invalid car size' } unless VALID_SIZES.include?(size_str)
    msg = @garage.admit_car(plate_str, size_str)
    if msg.start_with?('car with license plate no.')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tickets[plate_str] = ticket
      { success: true, message: msg, ticket: ticket }
    else
      { success: false, message: msg }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tickets.delete(plate_str)
    return { success: false, message: 'No active ticket for this car' } unless ticket
    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    msg = @garage.exit_car(plate_str)
    { success: true, message: msg, fee: fee, duration_hours: duration }
  end

  def garage_status
    small = @garage.small_available
    medium = @garage.medium_available
    large = @garage.large_available
    {
      small_available: small,
      medium_available: medium,
      large_available: large,
      total_occupied: @garage.total_occupied,
      total_available: small + medium + large
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s.strip]
  end
end