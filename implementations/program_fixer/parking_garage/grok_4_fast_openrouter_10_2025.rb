require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    license = license_plate_no.to_s.strip
    return "Invalid license plate" if license.empty?

    size = car_size.to_s.downcase.strip
    unless %w[small medium large].include?(size)
      return "Invalid car size"
    end

    spot_type = allocate_spot(size)
    if spot_type
      @parking_spots[spot_type.to_sym] << { plate: license, size: size }
      "car with license plate no. #{license} is parked at #{spot_type}"
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    license = license_plate_no.to_s.strip
    return "Invalid license plate" if license.empty?

    car = nil
    spot_key = nil
    @parking_spots.each do |key, spots|
      car = spots.find { |c| c[:plate] == license }
      spot_key = key if car
      break if car
    end

    if car
      @parking_spots[spot_key].delete(car)
      case spot_key
      when :small
        @small += 1
      when :medium
        @medium += 1
      when :large
        @large += 1
      end
      "car with license plate no. #{license} exited"
    else
      "Car not found"
    end
  end

  private

  def allocate_spot(size)
    case size
    when 'small'
      if @small > 0
        @small -= 1
        return 'small'
      elsif @medium > 0
        @medium -= 1
        return 'medium'
      elsif @large > 0
        @large -= 1
        return 'large'
      end
    when 'medium'
      if @medium > 0
        @medium -= 1
        return 'medium'
      elsif @large > 0
        @large -= 1
        return 'large'
      elsif (freed = shuffle_to_park('medium'))
        send("#{freed}=", send(freed) - 1)
        return freed
      end
    when 'large'
      if @large > 0
        @large -= 1
        return 'large'
      elsif (freed = shuffle_to_park('large'))
        send("#{freed}=", send(freed) - 1)
        return freed
      end
    end
    nil
  end

  def shuffle_to_park(size)
    case size
    when 'large'
      candidate = @parking_spots[:large].find { |c| c[:size] != 'large' }
      return nil unless candidate

      target = case candidate[:size]
               when 'small'
                 @small > 0 ? :small : (@medium > 0 ? :medium : nil)
               when 'medium'
                 @medium > 0 ? :medium : nil
               else
                 nil
               end
      if target
        @parking_spots[:large].delete(candidate)
        @large += 1
        @parking_spots[target] << candidate
        if target == :small
          @small -= 1
        else
          @medium -= 1
        end
        return 'large'
      end
    when 'medium'
      # Try to free medium spot
      small_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if small_in_medium && @small > 0
        @parking_spots[:medium].delete(small_in_medium)
        @medium += 1
        @parking_spots[:small] << small_in_medium
        @small -= 1
        return 'medium'
      end
      # Try to free large spot by moving small from large
      small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_in_large && @small > 0
        @parking_spots[:large].delete(small_in_large)
        @large += 1
        @parking_spots[:small] << small_in_large
        @small -= 1
        return 'large'
      end
    end
    nil
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase.strip
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24.0
  end
end

class ParkingFeeCalculator
  RATES = {
    small: 2.0,
    medium: 3.0,
    large: 5.0
  }.freeze

  MAX_FEES = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || duration_hours < 0
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size.to_sym)

    if duration_hours <= GRACE_PERIOD
      return 0.0
    end

    billable_hours = duration_hours - GRACE_PERIOD
    hours = billable_hours.ceil
    rate = RATES[size.to_sym]
    total = hours * rate
    [total, MAX_FEES[size]].min
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    license = plate.to_s.strip
    return { success: false, message: "Invalid license plate" } if license.empty?
    car_size = size.to_s.downcase.strip
    return { success: false, message: "Invalid car size" } unless %w[small medium large].include?(car_size)

    message = @garage.admit_car(license, car_size)
    if message.include?("parked")
      ticket = ParkingTicket.new(license, car_size)
      @tickets[license] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    license = plate.to_s.strip
    return { success: false, message: "Invalid license plate" } if license.empty?

    ticket = @tickets[license]
    return { success: false, message: "No valid ticket" } unless ticket && ticket.valid?

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(license)
    if message.include?("exited")
      @tickets.delete(license)
      { success: true, message: message, fee: fee, duration_hours: duration }
    else
      { success: false, message: message }
    end
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large
    total_occupied = @tickets.size
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    license = plate.to_s.strip
    @tickets[license]
  end
end