require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

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

  def admit_car(license_plate_no, car_size)
    car_size = car_size.to_s.downcase.strip
    license_plate_no = license_plate_no.to_s

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << { plate: license_plate_no, size: car_size }
        @small -= 1
        "car with license plate no. #{license_plate_no} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << { plate: license_plate_no, size: car_size }
        @medium -= 1
        "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << { plate: license_plate_no, size: car_size }
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << { plate: license_plate_no, size: car_size }
        @medium -= 1
        "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << { plate: license_plate_no, size: car_size }
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        "No space available"
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << { plate: license_plate_no, size: car_size }
        @large -= 1
        "car with license plate no. #{license_plate_no} is parked at large"
      else
        "No space available"
      end
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s
    [:small, :medium, :large].each do |spot_type|
      index = @parking_spots[spot_type].index { |c| c[:plate] == license_plate_no }
      if index
        @parking_spots[spot_type].delete_at(index)
        case spot_type
        when :small then @small += 1
        when :medium then @medium += 1
        when :large then @large += 1
        end
        break
      end
    end
    "car with license plate no. #{license_plate_no} exited"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase.strip
    @entry_time    = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0)
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = {
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || duration_hours <= 0
    duration_hours = duration_hours.to_f
    return 0.0 if duration_hours <= 0.25

    hours = duration_hours.ceil
    rate = RATES[car_size.to_s.downcase.strip] || 0.0
    total = hours * rate
    [total, MAX_FEE[car_size.to_s.downcase.strip] || 999.0].min
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @initial_small = small_spots.to_i
    @initial_medium = medium_spots.to_i
    @initial_large = large_spots.to_i
    @garage = ParkingGarage.new(small_spots.to_i, medium_spots.to_i, large_spots.to_i)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid input" } if plate.nil? || plate.to_s.strip.empty?
    size_str = size.to_s.downcase.strip if size
    return { success: false, message: "Invalid input" } if !%w[small medium large].include?(size_str)

    message = @garage.admit_car(plate, size_str)

    if message.start_with?("car with license plate")
      ticket = ParkingTicket.new(plate, size_str)
      @active_tickets[plate.to_s] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s if plate
    return { success: false, message: "Invalid input" } unless plate_str && !plate_str.strip.empty?

    ticket = @active_tickets[plate_str]
    return { success: false, message: "No active ticket for #{plate_str}" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(plate_str)
    @active_tickets.delete(plate_str)
    { success: true, message: message, fee: fee, duration_hours: duration }
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large
    total_occupied = (@initial_small + @initial_medium + @initial_large) - total_available
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: [total_occupied, 0].max,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s]
  end
end