require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @parking_spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    return 'No space available' if plate.empty?

    size = car_size.to_s.downcase
    unless %w[small medium large].include?(size)
      return 'No space available'
    end

    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        return park_msg(plate, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        return park_msg(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        return park_msg(plate, 'large')
      else
        'No space available'
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        return park_msg(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        return park_msg(plate, 'large')
      else
        'No space available'
      end
    when 'large'
      if @large > 0 || make_space_for_large()
        @parking_spots[:large] << kar
        @large -= 1
        park_msg(plate, 'large')
      else
        'No space available'
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    return 'car not found' if plate.empty?

    if car = @parking_spots[:small].find { |c| c[:plate] == plate }
      @parking_spots[:small].delete(car)
      @small += 1
      return "car with license plate no. #{plate} exited"
    elsif car = @parking_spots[:medium].find { |c| c[:plate] == plate }
      @parking_spots[:medium].delete(car)
      @medium += 1
      return "car with license plate no. #{plate} exited"
    elsif car = @parking_spots[:large].find { |c| c[:plate] == plate }
      @parking_spots[:large].delete(car)
      @large += 1
      return "car with license plate no. #{plate} exited"
    end

    'car not found'
  end

  private

  def park_msg(plate, spot_type)
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def make_space_for_large
    # Prefer moving medium first
    if @medium > 0
      med_car = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      if med_car
        move_car_to(med_car, :medium)
        return true
      end
    end

    # Then small
    small_car = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if small_car
      if @small > 0
        move_car_to(small_car, :small)
        return true
      elsif @medium > 0
        move_car_to(small_car, :medium)
        return true
      end
    end

    false
  end

  def move_car_to(car, target_type)
    @parking_spots[:large].delete(car)
    @large += 1
    @parking_spots[target_type] << car
    case target_type
    when :small
      @small -= 1
    when :medium
      @medium -= 1
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
    @id = SecureRandom.uuid
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  def calculate_fee(car_size, duration_hours)
    return 0.0 unless duration_hours.is_a?(Numeric) && duration_hours > 0
    car_size = car_size.to_s.downcase
    case car_size
    when 'small'
      rate = 2.0
      max_fee = 20.0
    when 'medium'
      rate = 3.0
      max_fee = 30.0
    when 'large'
      rate = 5.0
      max_fee = 50.0
    else
      return 0.0
    end

    return 0.0 if duration_hours <= 0.25

    hours = duration_hours.ceil
    fee = hours * rate
    [fee, max_fee].min
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    return { success: false, message: 'Invalid license plate' } if plate_str.empty?

    size_str = size.to_s.downcase
    unless %w[small medium large].include?(size_str)
      return { success: false, message: 'Invalid car size' }
    end

    result = @garage.admit_car(plate_str, size_str)
    if result == 'No space available'
      { success: false, message: result }
    else
      ticket = ParkingTicket.new(plate_str, size_str)
      @tickets[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    return { success: false, message: 'Invalid license plate' } if plate_str.empty?

    ticket = @tickets[plate_str]
    return { success: false, message: 'No ticket found' } unless ticket

    return { success: false, message: 'Ticket expired' } unless ticket.valid?

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    exit_msg = @garage.exit_car(plate_str)

    if exit_msg.include?('exited')
      @tickets.delete(plate_str)
      { success: true, message: exit_msg, fee: fee, duration_hours: duration }
    else
      { success: false, message: exit_msg }
    end
  end

  def garage_status
    small_available = @garage.small
    medium_available = @garage.medium
    large_available = @garage.large
    total_available = small_available + medium_available + large_available
    total_occupied = @garage.parking_spots[:small].size +
                     @garage.parking_spots[:medium].size +
                     @garage.parking_spots[:large].size

    {
      small_available: small_available,
      medium_available: medium_available,
      large_available: large_available,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end
end