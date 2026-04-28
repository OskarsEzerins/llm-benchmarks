require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase

    return "No space available" unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }
    spot = nil

    case size
    when 'small'
      spot = :small if park(car, :small)
      spot = :medium if spot.nil? && park(car, :medium)
      spot = :large if spot.nil? && park(car, :large)
    when 'medium'
      spot = :medium if park(car, :medium)
      spot = :large if spot.nil? && park(car, :large)
    when 'large'
      if park(car, :large)
        spot = :large
      elsif move_medium_from_large_to_medium && park(car, :large)
        spot = :large
      end
    end

    spot ? "car with license plate no. #{plate} is parked at #{spot}" : "No space available"
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    [:small, :medium, :large].each do |type|
      car = @spots[type].find { |c| c[:plate] == plate }
      if car
        @spots[type].delete(car)
        case type
        when :small then @small += 1
        when :medium then @medium += 1
        when :large then @large += 1
        end
        return "car with license plate no. #{plate} exited"
      end
    end
    "car with license plate no. #{plate} not found"
  end

  private

  def park(car, type)
    return false unless case type
                        when :small then @small > 0
                        when :medium then @medium > 0
                        when :large then @large > 0
                        end
    @spots[type] << car
    case type
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
    true
  end

  def move_medium_from_large_to_medium
    return false if @medium <= 0
    car = @spots[:large].find { |c| c[:size] == 'medium' }
    return false unless car
    @spots[:large].delete(car)
    @spots[:medium] << car
    @large += 1
    @medium -= 1
    true
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = { small: 2.0, medium: 3.0, large: 5.0 }
  DAILY_MAX = { small: 20.0, medium: 30.0, large: 50.0 }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || duration_hours <= 0.25

    size = car_size.to_s.downcase
    rate = RATES[size.to_sym] || 0.0
    max_fee = DAILY_MAX[size.to_sym]

    hours = duration_hours.ceil
    total = hours * rate

    [total, max_fee || total].min
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    msg = @garage.admit_car(plate, size)
    if msg.include?("parked")
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate.to_s] = ticket
      { success: true, message: msg, ticket: ticket }
    else
      { success: false, message: msg }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tickets[plate_str]
    return { success: false, message: "Ticket not found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    msg = @garage.exit_car(plate)
    @tickets.delete(plate_str)

    { success: true, message: msg, fee: fee.to_f, duration_hours: ticket.duration_hours }
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
    @tickets[plate.to_s]
  end
end