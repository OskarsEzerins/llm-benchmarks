require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i

    @parking_spots = {
      tiny_spot: [],
      mid_spot: [],
      grande_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return { success: false, message: "Invalid license plate" } if license_plate_no.nil? || license_plate_no.to_s.strip.empty?
    size = car_size.to_s.downcase
    return { success: false, message: "Invalid car size" } unless ['small', 'medium', 'large'].include?(size)

    case size
    when 'small'
      if @small > 0
        @parking_spots[:tiny_spot] << { plate: license_plate_no, size: size }
        @small -= 1
        return { success: true, message: "car with license plate no. #{license_plate_no} is parked at small" }
      elsif @medium > 0
        @parking_spots[:mid_spot] << { plate: license_plate_no, size: size }
        @medium -= 1
        return { success: true, message: "car with license plate no. #{license_plate_no} is parked at medium" }
      elsif @large > 0
        @parking_spots[:grande_spot] << { plate: license_plate_no, size: size }
        @large -= 1
        return { success: true, message: "car with license plate no. #{license_plate_no} is parked at large" }
      else
        return { success: false, message: "No space available" }
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:mid_spot] << { plate: license_plate_no, size: size }
        @medium -= 1
        return { success: true, message: "car with license plate no. #{license_plate_no} is parked at medium" }
      elsif @large > 0
        @parking_spots[:grande_spot] << { plate: license_plate_no, size: size }
        @large -= 1
        return { success: true, message: "car with license plate no. #{license_plate_no} is parked at large" }
      else
        return { success: false, message: "No space available" }
      end
    when 'large'
      if @large > 0
        @parking_spots[:grande_spot] << { plate: license_plate_no, size: size }
        @large -= 1
        return { success: true, message: "car with license plate no. #{license_plate_no} is parked at large" }
      else
        return { success: false, message: "No space available" }
      end
    end
  end

  def exit_car(license_plate_no)
    return { success: false, message: "Invalid license plate" } if license_plate_no.nil? || license_plate_no.to_s.strip.empty?

    plate_str = license_plate_no.to_s
    small_car  = @parking_spots[:tiny_spot].detect { |c| c[:plate].to_s == plate_str }
    medium_car = @parking_spots[:mid_spot].detect { |c| c[:plate].to_s == plate_str }
    large_car  = @parking_spots[:grande_spot].detect { |c| c[:plate].to_s == plate_str }

    if small_car
      @parking_spots[:tiny_spot].delete(small_car)
      @small += 1
      return { success: true, message: "👋 #{license_plate_no} left" }
    elsif medium_car
      @parking_spots[:mid_spot].delete(medium_car)
      @medium += 1
      return { success: true, message: "👋 #{license_plate_no} left" }
    elsif large_car
      @parking_spots[:grande_spot].delete(large_car)
      @large += 1
      return { success: true, message: "👋 #{license_plate_no} left" }
    else
      return { success: false, message: "Car not found" }
    end
  end

  def shuffle_medium(kar)
    victims = @parking_spots[:mid_spot] + @parking_spots[:grande_spot]
    victim = victims.sample
    return unless victim

    where = if @parking_spots[:mid_spot].include?(victim)
              :mid_spot
            else
              :grande_spot
            end
    @parking_spots[where].delete(victim)
    # move victim to tiny_spot
    @parking_spots[:tiny_spot] << victim
    # add new car to the freed spot
    @parking_spots[where] << kar
    @small += 1
  end

  def shuffle_large(kar)
    # Move first medium-sized car from grande_spot if any
    first_medium = @parking_spots[:grande_spot].detect { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:grande_spot].delete(first_medium)
      @parking_spots[:mid_spot] << first_medium
      @parking_spots[:grande_spot] << kar
      @medium -= 1
    end
  end

  def parking_status(car = nil, space = nil)
    if car && space
      { success: true, message: "🚗  #{car[:plate]} parked @ #{space}" }
    else
      { success: false, message: '¯\_(ツ)_/¯' }
    end
  end

  def exit_status(plate = nil)
    plate ? { success: true, message: "👋 #{plate} left" } : { success: false, message: 'Ghost car?' }
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license = license_plate
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(2)
  end

  def valid?
    duration_hours <= 24
  end

  private

  def generate_ticket_id
    "TK-#{rand(10000)}"
  end
end

class ParkingFeeCalculator
  RATES = {
    small:  2.0,
    medium: 3.0,
    large:  5.0
  }

  MAX_FEES = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || duration_hours < 0
    # Grace period: first 0.25 hours free
    billable_hours = duration_hours - 0.25
    billable_hours = 0 if billable_hours < 0
    hours = billable_hours.ceil
    rate = RATES[car_size.to_s.downcase.to_sym] || RATES[:small]
    total = hours * rate
    max_fee = MAX_FEES[car_size.to_s.downcase] || 999
    [total, max_fee].min.round(2)
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)
    if verdict[:success]
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict[:message], ticket: ticket }
    else
      { success: false, message: verdict[:message] }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tix_in_flight[plate_str]
    unless ticket
      return { success: false, message: 'Ticket not found' }
    end
    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)
    @tix_in_flight.delete(plate_str)
    { success: true, message: result[:message], fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_available: @garage.small + @garage.medium + @garage.large,
      total_occupied: (@garage.small - @garage.small) + (@garage.medium - @garage.medium) + (@garage.large - @garage.large) + (@garage.small - @garage.small) + (@garage.medium - @garage.medium) + (@garage.large - @garage.large),
      spots_left: @garage.small + @garage.medium + @garage.large,
      active_tickets: @tix_in_flight.size
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end