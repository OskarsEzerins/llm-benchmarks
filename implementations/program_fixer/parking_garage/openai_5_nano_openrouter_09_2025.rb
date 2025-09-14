require 'securerandom'

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0)
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingGarage
  def initialize(small, medium, large)
    @limits = {
      small: small.to_i,
      medium: medium.to_i,
      large: large.to_i
    }
    @spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no
    size = car_size.to_s.downcase
    return { success: false, message: 'Invalid car size' } unless %w[small medium large].include?(size)

    case size
    when 'small'
      if @spots[:small].length < @limits[:small]
        @spots[:small] << { plate: plate.to_s, size: size }
        return { success: true, message: "car with license plate no. #{plate} is parked at small" }
      elsif @spots[:medium].length < @limits[:medium]
        @spots[:medium] << { plate: plate.to_s, size: size }
        return { success: true, message: "car with license plate no. #{plate} is parked at medium" }
      elsif @spots[:large].length < @limits[:large]
        @spots[:large] << { plate: plate.to_s, size: size }
        return { success: true, message: "car with license plate no. #{plate} is parked at large" }
      else
        return { success: false, message: 'No space available' }
      end
    when 'medium'
      if @spots[:medium].length < @limits[:medium]
        @spots[:medium] << { plate: plate.to_s, size: size }
        return { success: true, message: "car with license plate no. #{plate} is parked at medium" }
      elsif @spots[:large].length < @limits[:large]
        @spots[:large] << { plate: plate.to_s, size: size }
        return { success: true, message: "car with license plate no. #{plate} is parked at large" }
      else
        return { success: false, message: 'No space available' }
      end
    when 'large'
      if @spots[:large].length < @limits[:large]
        @spots[:large] << { plate: plate.to_s, size: size }
        return { success: true, message: "car with license plate no. #{plate} is parked at large" }
      else
        return { success: false, message: 'No space available' }
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    [:small, :medium, :large].each do |space|
      idx = @spots[space].find_index { |c| c[:plate] == plate }
      if idx
        @spots[space].delete_at(idx)
        return "car with license plate no. #{plate} exited"
      end
    end
    nil
  end

  def garage_status
    {
      small_available: @limits[:small] - @spots[:small].length,
      medium_available: @limits[:medium] - @spots[:medium].length,
      large_available: @limits[:large] - @spots[:large].length,
      total_occupied: @spots.values.map(&:length).sum,
      total_available: (@limits[:small] + @limits[:medium] + @limits[:large]) - @spots.values.map(&:length).sum
    }
  end
end

class ParkingFeeCalculator
  RATES = {
    small: 2.0,
    medium: 3.0,
    large: 5.0
  }

  GRACE_HOURS = 0.25

  MAX_FEE = {
    small: 20.0,
    medium: 30.0,
    large: 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || duration_hours < 0
    size = car_size.to_s.downcase.to_sym
    rate = RATES[size]
    return 0.0 unless rate
    chargeable = duration_hours - GRACE_HOURS
    hours_used = if chargeable <= 0
      0
    else
      chargeable.ceil
    end
    total = hours_used * rate
    max = MAX_FEE[size]
    [total, max].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets_in_flight = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s
    if plate.nil? || plate_str.strip.empty?
      return { success: false, message: 'Invalid license plate' }
    end

    size_str = size.to_s.downcase
    unless %w[small medium large].include?(size_str)
      return { success: false, message: 'Invalid car size' }
    end

    verdict = @garage.admit_car(plate_str, size_str)
    if verdict[:success]
      ticket = ParkingTicket.new(plate_str, size_str)
      @tickets_in_flight[plate_str] = ticket
      { success: true, message: verdict[:message], ticket: ticket }
    else
      { success: false, message: verdict[:message] }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tickets_in_flight[plate_str]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)
    @tickets_in_flight.delete(plate_str)

    if result
      { success: true, message: result, fee: fee.to_f, hours: duration }
    else
      { success: false, message: 'Car not found in garage' }
    end
  end

  def garage_status
    @garage.garage_status
  end

  def find_ticket(plate)
    @tickets_in_flight[plate.to_s]
  end
end