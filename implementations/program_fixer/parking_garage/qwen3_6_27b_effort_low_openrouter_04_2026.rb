require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase
    return "No space available" if plate.empty? || !%w[small medium large].include?(size)

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
        return "No space available"
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
        return "No space available"
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    found_spot = nil
    found_car = nil

    @parking_spots.each do |spot, cars|
      found_car = cars.find { |c| c[:plate] == plate }
      found_spot = spot
      break if found_car
    end

    return "Car not found" unless found_car

    @parking_spots[found_spot].delete(found_car)
    send("#{found_spot}=", send(found_spot) + 1)
    "car with license plate no. #{plate} exited"
  end

  private

  def shuffle_large(car)
    victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if victim && @medium > 0
      @parking_spots[:large].delete(victim)
      @parking_spots[:medium] << victim
      @large += 1
      @medium -= 1
      @parking_spots[:large] << car
      @large -= 1
      return "car with license plate no. #{car[:plate]} is parked at large"
    else
      return "No space available"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.at(entry_time.to_f)
  end

  def duration_hours
    (Time.now.to_f - @entry_time.to_f) / 3600.0
  end

  def valid?
    duration_hours < 24.0
  end
end

class ParkingFeeCalculator
  RATES = { 'small' => 2.0, 'medium' => 3.0, 'large' => 5.0 }.freeze
  MAX_FEE = { 'small' => 20.0, 'medium' => 30.0, 'large' => 50.0 }.freeze

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    duration = duration_hours.to_f
    return 0.0 if duration <= 0.25

    billable_hours = (duration - 0.25).ceil
    total = (billable_hours * RATES[size]).to_f
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    plate = plate.to_s.strip
    size = size.to_s.downcase
    return { success: false, message: "Invalid input" } if plate.empty? || !%w[small medium large].include?(size)

    result = @garage.admit_car(plate, size)

    if result.start_with?("car with license plate no.")
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate = plate.to_s.strip
    ticket = @active_tickets[plate]
    return { success: false, message: "Ticket not found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    garage_msg = @garage.exit_car(plate)
    @active_tickets.delete(plate)

    { success: true, message: garage_msg, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @active_tickets.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end