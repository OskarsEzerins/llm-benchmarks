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
    plate = license_plate_no.to_s.strip
    return 'No space available' if plate.empty?

    size = car_size.to_s.strip.downcase
    return 'No space available' unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        return "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return 'No space available'
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return 'No space available'
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return 'No space available'
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    [:small, :medium, :large].each do |spot_type|
      car = @parking_spots[spot_type].detect { |c| c[:plate] == plate }
      if car
        @parking_spots[spot_type].delete(car)
        case spot_type
        when :small; @small += 1
        when :medium; @medium += 1
        when :large; @large += 1
        end
        return "car with license plate no. #{plate} exited"
      end
    end
    'Car not found'
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time
  end

  def duration_hours
    return 0.0 if @entry_time.nil?
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
    return 0.0 if duration_hours.nil? || duration_hours < 0
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    if duration_hours <= 0.25
      return 0.0
    end

    billable_hours = duration_hours - 0.25
    hours_to_bill = billable_hours.ceil
    rate = RATES[size]
    total = hours_to_bill * rate

    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)

    if result.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate.to_s.strip] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tickets[plate_str]
    return { success: false, message: 'No ticket found' } unless ticket

    @garage.exit_car(plate)
    @tickets.delete(plate_str)

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    {
      success: true,
      message: "car with license plate no. #{plate_str} exited",
      fee: fee,
      duration_hours: ticket.duration_hours
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @tickets.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s.strip]
  end
end