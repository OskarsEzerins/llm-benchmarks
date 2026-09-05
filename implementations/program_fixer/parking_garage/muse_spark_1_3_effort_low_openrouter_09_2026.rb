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
    plate = license_plate_no.to_s.strip rescue ""
    size = car_size.to_s.strip.downcase rescue ""
    unless !plate.empty? && %w[small medium large].include?(size)
      return "No space available"
    end

    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        return parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return parking_status
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return shuffle_medium(kar)
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return shuffle_large(kar)
      end
    else
      return parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s rescue ""
    small_car  = @parking_spots[:small].detect { |c| c[:plate].to_s == plate }
    medium_car = @parking_spots[:medium].detect { |c| c[:plate].to_s == plate }
    large_car  = @parking_spots[:large].detect { |c| c[:plate].to_s == plate }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      return exit_status(plate)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      return exit_status(plate)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      return exit_status(plate)
    else
      return "Car not found"
    end
  end

  def shuffle_medium(kar)
    return parking_status
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:large].find { |c| c[:size].to_s == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large].delete(first_medium)
      @parking_spots[:medium] << first_medium
      @medium -= 1
      @large += 1
      @parking_spots[:large] << kar
      @large -= 1
      return parking_status(kar, 'large')
    end
    first_small_in_large = @parking_spots[:large].find { |c| c[:size].to_s == 'small' }
    if first_small_in_large
      if @small > 0
        @parking_spots[:large].delete(first_small_in_large)
        @parking_spots[:small] << first_small_in_large
        @small -= 1
        @large += 1
        @parking_spots[:large] << kar
        @large -= 1
        return parking_status(kar, 'large')
      elsif @medium > 0
        @parking_spots[:large].delete(first_small_in_large)
        @parking_spots[:medium] << first_small_in_large
        @medium -= 1
        @large += 1
        @parking_spots[:large] << kar
        @large -= 1
        return parking_status(kar, 'large')
      end
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
    if plate && !plate.to_s.strip.empty?
      "car with license plate no. #{plate} exited"
    else
      "Car not found"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate, :license, :car_siez

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @license = @license_plate
    @car_size = car_size.to_s.strip.downcase
    @car_siez = @car_size
    @entry_time = entry_time || Time.now
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).to_f
  end

  def valid?
    duration_hours <= 24
  end

  private

  def generate_ticket_id
    "TK-#{rand(9999)}"
  end
end

class ParkingFeeCalculator
  RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase rescue ""
    begin
      duration = Float(duration_hours)
    rescue
      return 0.0
    end
    return 0.0 if duration.nil? || duration < 0
    return 0.0 unless RATES.key?(size)
    return 0.0 if duration <= 0.25
    hours = duration.ceil
    rate = RATES[size]
    total = hours * rate
    max = MAX_FEE[size]
    [total.to_f, max.to_f].min.to_f
  end

  def calculate__fee(car_size, duration_hours)
    calculate_fee(car_size, duration_hours)
  end
end

class ParkingGarageManager
  def initialize(*args, small_spots: nil, medium_spots: nil, large_spots: nil, small: nil, medium: nil, large: nil)
    s = args[0].nil? ? (small_spots.nil? ? small : small_spots) : args[0]
    m = args[1].nil? ? (medium_spots.nil? ? medium : medium_spots) : args[1]
    l = args[2].nil? ? (large_spots.nil? ? large : large_spots) : args[2]
    s = 0 if s.nil?
    m = 0 if m.nil?
    l = 0 if l.nil?
    @garage = ParkingGarage.new(s, m, l)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
    @active_tickets = @tix_in_flight
  end

  def garage
    @garage
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)
    if verdict.to_s.include?('parked')
      norm_size = size.to_s.strip.downcase
      ticket = ParkingTicket.new(plate.to_s, norm_size)
      key = plate.to_s
      @tix_in_flight[key] = ticket
      { success: true, ok: true, message: verdict, msg: verdict, ticket: ticket, tix: ticket }
    else
      { success: false, ok: false, message: verdict, msg: verdict, ticket: nil, tix: nil }
    end
  end

  def exit_car(plate)
    key = plate.to_s
    ticket = @tix_in_flight[key]
    unless ticket
      found_key = @tix_in_flight.keys.find { |k| k.to_s == key }
      ticket = found_key ? @tix_in_flight[found_key] : nil
      key = found_key if found_key
    end
    return { success: false, ok: false, message: 'Car not found', msg: 'Car not found', fee: 0.0, duration_hours: 0.0, hours: 0.0 } unless ticket
    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate)
    @tix_in_flight.delete(key)
    { success: true, ok: true, message: result, msg: result, fee: fee.to_f, duration_hours: duration.to_f, hours: duration.to_f }
  end

  def garage_status
    small_a = @garage.small
    medium_a = @garage.medium
    large_a = @garage.large
    occupied = @garage.parking_spots.values.map(&:size).sum
    available = small_a + medium_a + large_a
    {
      small_available: small_a,
      medium_available: medium_a,
      large_available: large_a,
      total_occupied: occupied,
      total_available: available,
      small_open: small_a,
      med_open: small_a && medium_a ? medium_a : medium_a,
      medium_open: medium_a,
      lrg_open: large_a,
      large_open: large_a,
      spots_left: available,
      ticking: @tix_in_flight.size,
      active_tickets: @tix_in_flight.size
    }
  end

  def find_ticket(plate)
    key = plate.to_s
    return @tix_in_flight[key] if @tix_in_flight.key?(key)
    found = @tix_in_flight.keys.find { |k| k.to_s == key }
    found ? @tix_in_flight[found] : nil
  end

  private

  def garage_reader
    @garage
  end
end