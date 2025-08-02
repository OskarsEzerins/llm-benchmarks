require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    license_plate_no = license_plate_no.to_s.strip
    return "Invalid license plate" if license_plate_no.empty?
    car_size = car_size.to_s.downcase.strip
    return "Invalid car size" unless %w[small medium large].include?(car_size)
    kar = { plate: license_plate_no, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s.strip
    small_car = @parking_spots[:small].detect { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == license_plate_no }
    large_car = @parking_spots[:large].find { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      exit_status(license_plate_no)
    else
      exit_status
    end
  end

  def shuffle_medium(kar)
    candidates = (@parking_spots[:medium] + @parking_spots[:large]).select { |c| c[:size] == 'small' }
    victim = candidates.sample
    return parking_status unless victim && @small > 0

    where = @parking_spots.find { |key, arr| arr.include?(victim) }&.first
    return parking_status unless where

    @parking_spots[where].delete(victim)
    instance_variable_set("@#{where}", instance_variable_get("@#{where}") + 1)
    @parking_spots[:small] << victim
    @small -= 1
    @parking_spots[where] << kar
    instance_variable_set("@#{where}", instance_variable_get("@#{where}") - 1)
    parking_status(kar, where.to_s)
  end

  def shuffle_large(kar)
    large_list = @parking_spots[:large]
    first_medium = large_list.find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      large_list.delete(first_medium)
      @large += 1
      @parking_spots[:medium] << first_medium
      @medium -= 1
      large_list << kar
      @large -= 1
      return parking_status(kar, 'large')
    end
    first_small = large_list.find { |c| c[:size] == 'small' }
    if first_small && @small > 0
      large_list.delete(first_small)
      @large += 1
      @parking_spots[:small] << first_small
      @small -= 1
      large_list << kar
      @large -= 1
      return parking_status(kar, 'large')
    end
    parking_status
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : "No such car"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license = license_plate
    @car_size = car_size
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - entry_time) / 3600.0
  end

  def valid?
    (Time.now - entry_time) <= 24 * 3600
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
    return 0.0 if duration_hours <= 0
    size = car_size.to_s.downcase
    rate = RATES[size] || 0.0
    max_fee = MAX_FEE[size] || Float::INFINITY
    if duration_hours <= 0.25
      0.0
    else
      billable = duration_hours - 0.25
      hours = billable.ceil
      fee = hours.to_f * rate
      [fee, max_fee].min
    end
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    ticket = @tix_in_flight[plate.to_s]
    return { success: false, message: 'No such ticket' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate.to_s)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @tix_in_flight.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end