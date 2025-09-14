require 'securerandom'

class ParkingGarage
  attr_reader :small_available, :medium_available, :large_available

  def initialize(small, medium, large)
    @small_total = small.to_i
    @medium_total = medium.to_i
    @large_total = large.to_i
    @small_available = @small_total
    @medium_available = @medium_total
    @large_available = @large_total
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate_str = license_plate_no.to_s.strip
    size_str = car_size.to_s.downcase.strip if car_size

    return "Invalid license plate or car size" if plate_str.empty? || !['small', 'medium', 'large'].include?(size_str)

    car = { plate: plate_str, size: size_str }

    case size_str
    when 'small'
      if @small_available > 0
        @parking_spots[:small] << car
        @small_available -= 1
        "car with license plate no. #{plate_str} is parked at small"
      elsif @medium_available > 0
        @parking_spots[:medium] << car
        @medium_available -= 1
        "car with license plate no. #{plate_str} is parked at medium"
      elsif @large_available > 0
        @parking_spots[:large] << car
        @large_available -= 1
        "car with license plate no. #{plate_str} is parked at large"
      else
        "No space available"
      end
    when 'medium'
      if @medium_available > 0
        @parking_spots[:medium] << car
        @medium_available -= 1
        "car with license plate no. #{plate_str} is parked at medium"
      elsif @large_available > 0
        @parking_spots[:large] << car
        @large_available -= 1
        "car with license plate no. #{plate_str} is parked at large"
      else
        shuffle_medium(car) || "No space available"
      end
    when 'large'
      if @large_available > 0
        @parking_spots[:large] << car
        @large_available -= 1
        "car with license plate no. #{plate_str} is parked at large"
      else
        shuffle_large(car) || "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    plate_str = license_plate_no.to_s.strip
    return "Invalid license plate" if plate_str.empty?

    [:small, :medium, :large].each do |spot_type|
      car_index = @parking_spots[spot_type].find_index { |c| c[:plate] == plate_str }
      if car_index
        @parking_spots[spot_type].delete_at(car_index)
        case spot_type
        when :small
          @small_available += 1
        when :medium
          @medium_available += 1
        when :large
          @large_available += 1
        end
        return "car with license plate no. #{plate_str} exited"
      end
    end
    "Car not found"
  end

  private

  def shuffle_medium(car)
    # Attempt to find a small car in medium or large spots to move to small
    occupants = @parking_spots[:medium].select { |c| c[:size] == 'small' } +
                @parking_spots[:large].select { |c| c[:size] == 'small' }
    victim = occupants.sample
    if victim && @small_available > 0
      spot_key = @parking_spots[:medium].include?(victim) ? :medium : :large
      @parking_spots[spot_key].delete(victim)
      @parking_spots[:small] << victim
      @small_available -= 1
      if spot_key == :medium
        @medium_available += 1
      else
        @large_available += 1
      end
      # Park medium car in the vacated spot
      @parking_spots[spot_key == :medium ? :medium : :large] << car
      -(spot_key == :medium ? @medium_available : @large_available) if spot_key == :medium ? @medium_available < @medium_total : @large_available < @large_total
      spot_name = spot_key==:medium ? 'medium' : 'large'
      "car with license plate no. #{car[:plate]} is parked at #{spot_name}"
    end
  end

  def shuffle_large(car)
    # Find a medium in large spots to move to medium
    victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if victim && @medium_available < @medium_total
      @parking_spots[:large].delete(victim)
      @parking_spots[:medium] << victim
      @large_available += 1
      @medium_available -= 1
      @parking_spots[:large] << car
      @large_available -= 1
      "car with license plate no. #{car[:plate]} is parked at large"
    end
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

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
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = {
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }

  MAX_FEES = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase.strip
    return 0.0 unless RATES.key?(size)
    return 0.0 if duration_hours.negative? || duration_hours <= 0.25
    billable_hours = (duration_hours - 0.25).ceil
    total = billable_hours * RATES[size]
    [total, MAX_FEES[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)
    if result.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate.to_s.strip] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @active_tickets[plate_str]
    return { success: false, message: "No active ticket for #{plate_str}" } unless ticket
    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    exit_result = @garage.exit_car(plate_str)
    @active_tickets.delete(plate_str)
    { success: true, message: exit_result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small_available,
      medium_available: @garage.medium_available,
      large_available: @garage.large_available,
      total_occupied: (@garage.small_total + @garage.medium_total + @garage.large_total) - (@garage.small_available + @garage.medium_available + @garage.large_available),
      total_available: @garage.small_available + @garage.medium_available + @garage.large_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end