require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots

  def initialize(small, medium, large)
    @capacities = {
      small: small.to_i,
      medium: medium.to_i,
      large: large.to_i
    }
    @parking_spots = { small: [], medium: [], large: [] }
  end

  def small
    @capacities[:small] - @parking_spots[:small].size
  end

  def medium
    @capacities[:medium] - @parking_spots[:medium].size
  end

  def large
    @capacities[:large] - @parking_spots[:large].size
  end

  def admit_car(license_plate_no, car_size)
    license_plate_no = license_plate_no.to_s.strip
    if license_plate_no.empty?
      return "Invalid license plate"
    end

    car_size = car_size.to_s.downcase
    unless %w[small medium large].include?(car_size)
      return "Invalid car size"
    end

    kar = { plate: license_plate_no, size: car_size }

    case car_size
    when 'small'
      if small > 0
        @parking_spots[:small] << kar
        return park_message(kar, 'small')
      elsif medium > 0
        @parking_spots[:medium] << kar
        return park_message(kar, 'medium')
      elsif large > 0
        @parking_spots[:large] << kar
        return park_message(kar, 'large')
      else
        return "No space available"
      end

    when 'medium'
      if medium > 0
        @parking_spots[:medium] << kar
        return park_message(kar, 'medium')
      elsif large > 0
        @parking_spots[:large] << kar
        return park_message(kar, 'large')
      else
        return shuffle_medium(kar)
      end

    when 'large'
      if large > 0
        @parking_spots[:large] << kar
        return park_message(kar, 'large')
      else
        return shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    car = nil
    spot = nil

    [@parking_spots[:small], @parking_spots[:medium], @parking_spots[:large]].each do |spots|
      car = spots.find { |c| c[:plate] == plate }
      spot = spots if car
      break if car
    end

    if car
      spot.delete(car)
      return exit_message(plate)
    else
      return "Car not found"
    end
  end

  private

  def park_message(car, spot_type)
    "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
  end

  def exit_message(plate)
    "car with license plate no. #{plate} exited"
  end

  def shuffle_medium(kar)
    if small <= 0
      return "No space available"
    end

    candidates = @parking_spots[:medium].select { |c| c[:size] == 'small' } +
                 @parking_spots[:large].select { |c| c[:size] == 'small' }

    return "No space available" if candidates.empty?

    victim = candidates.first
    where = @parking_spots[:medium].include?(victim) ? :medium : :large

    @parking_spots[where].delete(victim)
    @parking_spots[:small] << victim
    @parking_spots[where] << kar

    park_message(kar, where.to_s)
  end

  def shuffle_large(kar)
    # Try to move medium from large to medium
    med_victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if med_victim && medium > 0
      @parking_spots[:large].delete(med_victim)
      @parking_spots[:medium] << med_victim
      @parking_spots[:large] << kar
      return park_message(kar, 'large')
    end

    # Try to move small from large to small or medium
    small_victim = @parking_spots[:large].find { |c| c[:size] == 'small' }
    target = if small > 0
               :small
             elsif medium > 0
               :medium
             else
               nil
             end

    if small_victim && target
      @parking_spots[:large].delete(small_victim)
      @parking_spots[target] << small_victim
      @parking_spots[:large] << kar
      return park_message(kar, 'large')
    end

    "No space available"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(1)
  end

  def valid?
    (Time.now - @entry_time) < 24 * 3600
  end
end

class ParkingFeeCalculator
  RATES = {
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }.freeze

  MAX_FEES = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    car_size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(car_size)
    return 0.0 if duration_hours.nil? || duration_hours < 0

    billable_hours = [duration_hours - GRACE_PERIOD, 0].max
    hours = billable_hours.ceil
    rate = RATES[car_size]
    total = hours * rate
    [total, MAX_FEES[car_size]].min
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
    @total_spots = small.to_i + medium.to_i + large.to_i
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    if plate_str.empty?
      return { success: false, message: "Invalid license plate" }
    end

    size_str = size.to_s.downcase
    unless %w[small medium large].include?(size_str)
      return { success: false, message: "Invalid car size" }
    end

    result = @garage.admit_car(plate_str, size_str)
    if result.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tickets[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tickets[plate_str]
    unless ticket && ticket.valid?
      return { success: false, message: ticket ? "Ticket expired" : "No valid ticket" }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)

    if result.include?('exited')
      @tickets.delete(plate_str)
      { success: true, message: result, fee: fee, duration_hours: duration }
    else
      { success: false, message: "Car not found" }
    end
  end

  def garage_status
    avail_small = @garage.small
    avail_medium = @garage.medium
    avail_large = @garage.large
    total_available = avail_small + avail_medium + avail_large
    total_occupied = @total_spots - total_available

    {
      small_available: avail_small,
      medium_available: avail_medium,
      large_available: avail_large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s]
  end
end