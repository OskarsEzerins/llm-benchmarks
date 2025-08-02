require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :initial_small, :initial_medium, :initial_large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @initial_small = @small
    @initial_medium = @medium
    @initial_large = @large
    @parking_spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.strip.downcase
    return "Invalid license plate" if plate.empty?
    return "Invalid car size" unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }
    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        return parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return parking_status(car, 'large')
      else
        return "No space available"
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return parking_status(car, 'large')
      else
        return "No space available"
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return parking_status(car, 'large')
      else
        return shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    car = @parking_spots[:small].find { |c| c[:plate] == plate } ||
          @parking_spots[:medium].find { |c| c[:plate] == plate } ||
          @parking_spots[:large].find { |c| c[:plate] == plate }
    unless car
      return exit_status(nil)
    end

    case
    when @parking_spots[:small].include?(car)
      @parking_spots[:small].delete(car)
      @small += 1
    when @parking_spots[:medium].include?(car)
      @parking_spots[:medium].delete(car)
      @medium += 1
    when @parking_spots[:large].include?(car)
      @parking_spots[:large].delete(car)
      @large += 1
    end
    exit_status(plate)
  end

  def shuffle_large(car)
    # Try to free up a large spot by moving a medium car from large to medium
    victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if victim && @medium > 0
      @parking_spots[:large].delete(victim)
      @parking_spots[:medium] << victim
      @medium -= 1
      @large += 1  # freed one large spot by moving victim out
      @parking_spots[:large] << car
      @large -= 1
      return parking_status(car, 'large')
    end
    "No space available"
  end

  def parking_status(car, spot)
    "car with license plate no. #{car[:plate]} is parked at #{spot}"
  end

  def exit_status(plate)
    if plate
      "car with license plate no. #{plate} exited"
    else
      "Ghost car?"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time + rand(60)
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(2)
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
  }

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    return -1 if !duration_hours.is_a?(Numeric) || duration_hours < 0
    return 0.0 if duration_hours <= 0.25

    billable_hours = (duration_hours - 0.25)
    billable_hours = billable_hours.ceil
    rate = RATES[size.to_sym] || 0.0
    total = billable_hours * rate
    [total, MAX_FEE[size] || total].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)
    if verdict.include?("parked")
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s.strip] = ticket
      { ok: true, msg: verdict, tix: ticket }
    else
      { ok: false, msg: verdict }
    end
  end

  def exit_car(plate)
    key = plate.to_s.strip
    ticket = @tix_in_flight[key]
    return { ok: false, msg: 'Ticket not found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)
    @tix_in_flight.delete(key)
    { ok: true, msg: result, fee: fee, hours: ticket.duration_hours }
  end

  def garage_status
    occupied_small = @garage.initial_small - @garage.small
    occupied_medium = @garage.initial_medium - @garage.medium
    occupied_large = @garage.initial_large - @garage.large
    total_occupied = occupied_small + occupied_medium + occupied_large
    total_available = @garage.small + @garage.medium + @garage.large
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: total_available,
      tickets_in_flight: @tix_in_flight.size
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end
end