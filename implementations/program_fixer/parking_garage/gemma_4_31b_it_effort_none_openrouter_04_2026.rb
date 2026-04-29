require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @parking_spots = {
      'small' => [],
      'medium' => [],
      'large' => []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "No space available" if license_plate_no.to_s.strip.empty?
    
    size = car_size.to_s.downcase
    kar = { plate: license_plate_no.to_s, size: size }

    case size
    when 'small'
      if @small > 0
        park_car(kar, 'small')
      elsif @medium > 0
        park_car(kar, 'medium')
      elsif @large > 0
        park_car(kar, 'large')
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        park_car(kar, 'medium')
      elsif @large > 0
        park_car(kar, 'large')
      else
        shuffle_medium(kar)
      end
    when 'large'
      if @large > 0
        park_car(kar, 'large')
      else
        shuffle_large(kar)
      end
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    found_spot = nil
    
    @parking_spots.each do |type, cars|
      car = cars.find { |c| c[:plate] == plate }
      if car
        found_spot = type
        cars.delete(car)
        break
      end
    end

    if found_spot
      update_count(found_spot, 1)
      "car with license plate no. #{plate} exited"
    else
      "Car not found"
    end
  end

  private

  def park_car(kar, spot_type)
    @parking_spots[spot_type] << kar
    update_count(spot_type, -1)
    "car with license plate no. #{kar[:plate]} is parked at #{spot_type}"
  end

  def update_count(type, delta)
    case type
    when 'small'  then @small += delta
    when 'medium' then @medium += delta
    when 'large'  then @large += delta
    end
  end

  def shuffle_medium(kar)
    victim = @parking_spots['large'].find { |c| c[:size] == 'small' || c[:size] == 'medium' }
    return "No space available" unless victim

    current_spot = @parking_spots.find { |type, cars| cars.include?(victim) }.first
    @parking_spots[current_spot].delete(victim)
    
    # Move victim to smaller spot if possible
    if victim[:size] == 'small' && @small > 0
      @parking_spots['small'] << victim
      @small -= 1
    elsif victim[:size] == 'small' && @medium > 0
      @parking_spots['medium'] << victim
      @medium -= 1
    elsif victim[:size] == 'medium' && @medium > 0
      @parking_spots['medium'] << victim
      @medium -= 1
    else
      return "No space available"
    end

    park_car(kar, current_spot)
  end

  def shuffle_large(kar)
    victim = @parking_spots['large'].find { |c| c[:size] == 'medium' }
    if victim && @medium > 0
      @parking_spots['large'].delete(victim)
      @parking_spots['medium'] << victim
      @medium -= 1
      return park_car(kar, 'large')
    end
    "No space available"
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
  MAX_FEE = { 'small' => 20.0, 'medium' => 30.0, 'large' => 50.0 }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.to_f <= 0.25
    return 0.0 if duration_hours.to_f <= 0

    size = car_size.to_s.downcase
    rate = RATES[size] || 0.0
    max = MAX_FEE[size] || 0.0
    
    fee = duration_hours.ceil * rate
    [fee.to_f, max.to_f].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)
    if result.start_with?("car with license plate")
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_s = plate.to_s
    ticket = @tix_in_flight[plate_s]
    return { success: false, message: "Ticket not found" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    msg = @garage.exit_car(plate_s)
    
    @tix_in_flight.delete(plate_s)
    { success: true, message: msg, fee: fee.to_f, duration_hours: duration }
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
end