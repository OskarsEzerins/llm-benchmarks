require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small_spot:   [],
      medium_spot:  [],
      large_spot:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    license_plate_no = license_plate_no.to_s.strip
    car_size = car_size.to_s.downcase.strip

    return "Invalid license plate" if license_plate_no.empty?
    return "Invalid car size" unless ['small', 'medium', 'large'].include?(car_size)

    kar = { plate: license_plate_no, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s.strip
    return "Invalid license plate" if license_plate_no.empty?

    small_car  = @parking_spots[:small_spot].find { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium_spot].find { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:large_spot].find { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      exit_status(license_plate_no)
    else
      exit_status
    end
  end

  def shuffle_medium(kar)
    victim = (@parking_spots[:medium_spot] + @parking_spots[:large_spot]).sample
    return parking_status unless victim

    where = @parking_spots.key(victim) || :medium_spot
    @parking_spots[where].delete(victim)
    @parking_spots[:small_spot] << victim
    @small -= 1
    @parking_spots[where] << kar
    parking_status(kar, where.to_s.sub('_spot', ''))
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large_spot].delete(first_medium)
      @parking_spots[:medium_spot] << first_medium
      @parking_spots[:large_spot] << kar
      @medium -= 1
      parking_status(kar, 'large')
    else
      parking_status
    end
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : "No such car parked"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase.strip
    @entry_time = entry_time
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0].max
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.hex(4)}"
  end
end

class ParkingFeeCalculator
  RATES = {
    small:  2.0,
    medium: 3.0,
    large:  5.0
  }

  MAX_FEES = {
    small:  20.0,
    medium: 30.0,
    large:  50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= 0.25

    car_size = car_size.to_s.downcase.to_sym
    return 0.0 unless RATES.key?(car_size)

    hours = [duration_hours.ceil, 1].max
    total = hours * RATES[car_size]
    [total, MAX_FEES[car_size]].min
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

    if result.start_with?('car with license plate')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate.to_s.strip] = ticket
      {
        success: true,
        message: result,
        ticket: ticket
      }
    else
      {
        success: false,
        message: result
      }
    end
  end

  def exit_car(plate)
    plate = plate.to_s.strip
    ticket = @active_tickets[plate]

    unless ticket && ticket.valid?
      return {
        success: false,
        message: "Invalid or expired ticket for #{plate}"
      }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @active_tickets.delete(plate)
    {
      success: true,
      message: result,
      fee: fee,
      duration_hours: ticket.duration_hours
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.parking_spots.values.sum(&:size),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end