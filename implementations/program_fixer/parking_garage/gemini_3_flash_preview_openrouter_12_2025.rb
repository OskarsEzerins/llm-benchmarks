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
    return "No space available" if license_plate_no.to_s.strip.empty?
    
    plate = license_plate_no.to_string rescue license_plate_no.to_s
    size = car_size.to_s.downcase
    kar = { plate: plate, size: size }

    case size
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
        "No space available"
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
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    
    if (car = @parking_spots[:small].find { |c| c[:plate] == plate })
      @parking_spots[:small].delete(car)
      @small += 1
      exit_status(plate)
    elsif (car = @parking_spots[:medium].find { |c| c[:plate] == plate })
      @parking_spots[:medium].delete(car)
      @medium += 1
      exit_status(plate)
    elsif (car = @parking_spots[:large].find { |c| c[:plate] == plate })
      @parking_spots[:large].delete(car)
      @large += 1
      exit_status(plate)
    else
      "car with license plate no. #{plate} not found"
    end
  end

  def shuffle_medium(kar)
    # If a small car is taking a medium spot and there's a small spot open
    victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
    if victim && @small > 0
      @parking_spots[:medium].delete(victim)
      @small -= 1
      @parking_spots[:small] << victim
      @parking_spots[:medium] << kar
      return parking_status(kar, 'medium')
    end
    "No space available"
  end

  def shuffle_large(kar)
    # If a medium car is taking a large spot and there's a medium spot open
    victim = @parking_spots[:large].find { |c| c[:size] == 'medium' || c[:size] == 'small' }
    if victim
      if victim[:size] == 'medium' && @medium > 0
        @parking_spots[:large].delete(victim)
        @medium -= 1
        @parking_spots[:medium] << victim
        @parking_spots[:large] << kar
        return parking_status(kar, 'large')
      elsif victim[:size] == 'small' && @small > 0
        @parking_spots[:large].delete(victim)
        @small -= 1
        @parking_spots[:small] << victim
        @parking_spots[:large] << kar
        return parking_status(kar, 'large')
      end
    end
    "No space available"
  end

  def parking_status(car, space)
    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate)
    "car with license plate no. #{plate} exited"
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
  RATES = { 'small' => 2.0, 'medium' => 3.0, 'large' => 5.0 }
  MAX_FEES = { 'small' => 20.0, 'medium' => 30.0, 'large' => 50.0 }
  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return 0.0 if duration_hours <= GRACE_PERIOD || duration_hours <= 0
    
    hours = duration_hours.ceil
    rate = RATES[size] || 0.0
    total = hours * rate
    
    max = MAX_FEES[size] || 0.0
    [total.to_f, max.to_f].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    clean_size = size.to_s.downcase
    unless ['small', 'medium', 'large'].include?(clean_size)
      return { success: false, message: "No space available" }
    end

    message = @garage.admit_car(plate, clean_size)
    if message.include?('parked')
      ticket = ParkingTicket.new(plate, clean_size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    ticket = @tix_in_flight[plate.to_s]
    return { success: false, message: "Ticket not found" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(plate)
    
    @tix_in_flight.delete(plate.to_s)
    { success: true, message: message, fee: fee, duration_hours: duration }
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