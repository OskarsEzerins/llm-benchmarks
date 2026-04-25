require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @parking_spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate_no, car_size)
    return "Invalid input" if license_plate_no.nil? || car_size.nil?
    plate = license_plate_no.to_s.strip
    return "Invalid input" if plate.empty?
    size = car_size.to_s.downcase
    return "Invalid car size" unless %w[small medium large].include?(size)

    spot_type = nil

    case size
    when 'small'
      if @small > 0
        spot_type = :small
        @small -= 1
      elsif @medium > 0
        spot_type = :medium
        @medium -= 1
      elsif @large > 0
        spot_type = :large
        @large -= 1
      end
    when 'medium'
      if @medium > 0
        spot_type = :medium
        @medium -= 1
      elsif @large > 0
        spot_type = :large
        @large -= 1
      end
    when 'large'
      if @large > 0
        spot_type = :large
        @large -= 1
      end
    end

    if spot_type
      car = { plate: plate, size: size }
      @parking_spots[spot_type] << car
      "car with license plate no. #{plate} is parked at #{spot_type}"
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    found_spot = nil

    [:small, :medium, :large].each do |spot|
      @parking_spots[spot].each_with_index do |car, idx|
        if car[:plate] == plate
          @parking_spots[spot].delete_at(idx)
          found_spot = spot
          break
        end
      end
      break if found_spot
    end

    return "Car not found" unless found_spot

    case found_spot
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end

    "car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase
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
  RATES = { small: 2.0, medium: 3.0, large: 5.0 }
  MAX_FEE = { small: 20.0, medium: 30.0, large: 50.0 }

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    dur = duration_hours.to_f

    return 0.0 if dur <= 0.0
    return 0.0 if dur <= 0.25

    hours = dur.ceil
    rate = RATES[size] || 0.0
    fee = hours * rate

    [fee, MAX_FEE[size] || Float::INFINITY].min.to_f
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
    msg = @garage.admit_car(plate, size)
    if msg.include?('parked at')
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate.to_s.strip] = ticket
      { success: true, message: msg, ticket: ticket }
    else
      { success: false, message: msg }
    end
  end

  def exit_car(plate)
    p = plate.to_s.strip
    ticket = @tickets.delete(p)
    return { success: false, message: "Ticket not found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    msg = @garage.exit_car(plate)
    { success: true, message: msg, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    s = @garage.small
    m = @garage.medium
    l = @garage.large
    total_avail = s + m + l
    total_occupied = @total_spots - total_avail
    {
      small_available: s,
      medium_available: m,
      large_available: l,
      total_occupied: total_occupied,
      total_available: total_avail
    }
  end

  def find_ticket(plate)
    @tickets.fetch(plate.to_s.strip, nil)
  end
end