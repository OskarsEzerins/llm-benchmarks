require 'securerandom'

class ParkingGarage
  attr_reader :small_available, :medium_available, :large_available

  def initialize(small, medium, large)
    @small_available  = small.to_i
    @medium_available = medium.to_i
    @large_available  = large.to_i
    @parking_spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate, car_size)
    plate = license_plate.to_s.strip
    size  = car_size.to_s.downcase.strip
    return "Invalid license plate" if plate.empty?
    return "Invalid car size" unless %w[small medium large].include?(size)

    spot = case size
    when 'small'
      if @small_available > 0
        :small
      elsif @medium_available > 0
        :medium
      elsif @large_available > 0
        :large
      else
        return "No space available"
      end
    when 'medium'
      if @medium_available > 0
        :medium
      elsif @large_available > 0
        :large
      else
        return "No space available"
      end
    when 'large'
      if @large_available > 0
        :large
      else
        # attempt to shuffle a medium from large -> medium
        victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
        if victim && @medium_available > 0
          @parking_spots[:large].delete(victim)
          @parking_spots[:medium] << victim
          @medium_available -= 1
          @large_available += 1
          :large
        else
          return "No space available"
        end
      end
    end

    @parking_spots[spot] << { plate: plate, size: size }
    case spot
    when :small  then @small_available  -= 1
    when :medium then @medium_available -= 1
    when :large  then @large_available  -= 1
    end
    "car with license plate no. #{plate} is parked at #{spot}"
  end

  def exit_car(license_plate)
    plate = license_plate.to_s.strip
    spot_entry = @parking_spots.find { |_spot, cars| cars.any? { |c| c[:plate] == plate } }
    return "No such car" unless spot_entry

    spot_type, cars = spot_entry
    car = cars.find { |c| c[:plate] == plate }
    cars.delete(car)
    case spot_type
    when :small  then @small_available  += 1
    when :medium then @medium_available += 1
    when :large  then @large_available  += 1
    end
    "car with license plate no. #{plate} exited"
  end

  def garage_status
    {
      small_available:  @small_available,
      medium_available: @medium_available,
      large_available:  @large_available,
      total_occupied:   @parking_spots.values.map(&:size).sum,
      total_available:  @small_available + @medium_available + @large_available
    }
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
    ((Time.now - @entry_time) / 3600.0).round(2)
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = { 'small' => 2.0, 'medium' => 3.0, 'large' => 5.0 }
  DAILY_MAX = { 'small' => 20.0, 'medium' => 30.0, 'large' => 50.0 }
  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return -1.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours <= GRACE_PERIOD
    return 0.0 unless RATES.key?(size)

    billable = duration_hours - GRACE_PERIOD
    hours = billable.ceil
    fee = hours * RATES[size]
    fee = DAILY_MAX[size] if fee > DAILY_MAX[size]
    fee.round(2)
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets        = {}
  end

  def admit_car(plate, size)
    message = @garage.admit_car(plate, size)
    if message.start_with?('car with license plate no.')
      ticket_key = plate.to_s
      ticket = ParkingTicket.new(ticket_key, size)
      @tickets[ticket_key] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    key = plate.to_s
    ticket = @tickets[key]
    return { success: false, message: 'no ticket found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(key)
    @tickets.delete(key)
    { success: true, message: message, fee: fee, duration_hours: duration }
  end

  def garage_status
    @garage.garage_status
  end

  def find_ticket(plate)
    @tickets[plate.to_s]
  end
end