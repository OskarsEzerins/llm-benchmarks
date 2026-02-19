require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @small = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large = [large.to_i, 0].max
    @parking_spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase.strip

    return "No space available" if plate.empty? || !['small', 'medium', 'large'].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0 then park(car, :small)
      elsif @medium > 0 then park(car, :medium)
      elsif @large > 0 then park(car, :large)
      else "No space available"
      end
    when 'medium'
      if @medium > 0 then park(car, :medium)
      elsif @large > 0 then park(car, :large)
      else try_shuffle_for_medium(car)
      end
    when 'large'
      if @large > 0 then park(car, :large)
      else try_shuffle_for_large(car)
      end
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    return "Invalid plate" if plate.empty?

    [:small, :medium, :large].each do |spot_type|
      if idx = @parking_spots[spot_type].index { |c| c[:plate] == plate }
        @parking_spots[spot_type].delete_at(idx)
        increment_spot(spot_type)
        return "car with license plate no. #{plate} exited"
      end
    end
    "car not found"
  end

  private

  def park(car, spot_type)
    @parking_spots[spot_type] << car
    decrement_spot(spot_type)
    "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
  end

  def move_car(car, from_spot, to_spot)
    @parking_spots[from_spot].delete(car)
    @parking_spots[to_spot] << car
    decrement_spot(to_spot)
    increment_spot(from_spot)
  end

  def decrement_spot(spot_type)
    case spot_type
    when :small; @small -= 1
    when :medium; @medium -= 1
    when :large; @large -= 1
    end
  end

  def increment_spot(spot_type)
    case spot_type
    when :small; @small += 1
    when :medium; @medium += 1
    when :large; @large += 1
    end
  end

  def try_shuffle_for_medium(car)
    if @small > 0
      s_car = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if s_car
        move_car(s_car, :medium, :small)
        return park(car, :medium)
      end

      s_car_l = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if s_car_l
        move_car(s_car_l, :large, :small)
        return park(car, :large)
      end
    end
    "No space available"
  end

  def try_shuffle_for_large(car)
    if @small > 0
      s_car = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if s_car
        move_car(s_car, :large, :small)
        return park(car, :large)
      end
    end

    if @medium > 0
      ms_car = @parking_spots[:large].find { |c| %w[small medium].include?(c[:size]) }
      if ms_car
        move_car(ms_car, :large, :medium)
        return park(car, :large)
      end
    end
    "No space available"
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase.strip
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).to_f
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
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  def calculate_fee(car_size, duration_hours)
    return 0.0 unless duration_hours.is_a?(Numeric) && duration_hours > 0
    return 0.0 if duration_hours <= 0.25 # Grace period

    size = car_size.to_s.downcase.strip
    rate = RATES[size] || RATES['small']
    max_fee = MAX_FEE[size] || MAX_FEE['small']

    hours = duration_hours.ceil
    fee = hours * rate
    [fee, max_fee].min.to_f
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str = size.to_s.downcase.strip

    unless %w[small medium large].include?(size_str) && !plate_str.empty?
      return { success: false, message: "Invalid input" }
    end

    result = @garage.admit_car(plate_str, size_str)

    if result.include?('is parked at')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tickets[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tickets[plate_str]

    return { success: false, message: "Ticket not found for plate #{plate_str}" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)

    @tickets.delete(plate_str)

    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    occupied = @tickets.size
    small_avail = @garage.small
    medium_avail = @garage.medium
    large_avail = @garage.large
    total_avail = small_avail + medium_avail + large_avail

    {
      small_available: small_avail,
      medium_available: medium_avail,
      large_available: large_avail,
      total_occupied: occupied,
      total_available: total_avail
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s.strip]
  end
end