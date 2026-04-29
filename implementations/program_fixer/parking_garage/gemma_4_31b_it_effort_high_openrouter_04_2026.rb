require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

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
    return "No space available" if license_plate_no.to_s.strip.empty? || !['small', 'medium', 'large'].include?(car_size)

    kar = { plate: license_plate_no.to_s, size: car_size }

    case car_size
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
    spot_type = nil
    car_to_remove = nil

    @parking_spots.each do |type, cars|
      if (car = cars.find { |c| c[:plate] == plate })
        spot_type = type
        car_to_remove = car
        break
      end
    end

    if car_to_remove
      @parking_spots[spot_type].delete(car_to_remove)
      update_capacity(spot_type, 1)
      "car with license plate no. #{plate} exited"
    else
      "Car not found"
    end
  end

  def garage_status
    {
      small_available: @small,
      medium_available: @medium,
      large_available: @large,
      total_occupied: @parking_spots.values.flatten.size,
      total_available: @small + @medium + @large
    }
  end

  private

  def park_car(car, spot_type)
    @parking_spots[spot_type] << car
    update_capacity(spot_type, -1)
    "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
  end

  def update_capacity(type, delta)
    case type
    when 'small' then @small += delta
    when 'medium' then @medium += delta
    when 'large' then @large += delta
    end
  end

  def shuffle_medium(kar)
    # Try to move a small car from a medium spot to a small spot
    victim = @parking_spots['medium'].find { |c| c[:size] == 'small' }
    if victim && @small > 0
      @parking_spots['medium'].delete(victim)
      @parking_spots['small'] << victim
      @small -= 1
      park_car(kar, 'medium')
    else
      "No space available"
    end
  end

  def shuffle_large(kar)
    # Try to move a small or medium car from a large spot to a smaller spot
    victim = @parking_spots['large'].find { |c| c[:size] != 'large' }
    if victim
      v_size = victim[:size]
      target_spot = (v_size == 'small' && @small > 0) ? 'small' : (v_size == 'medium' && @medium > 0) ? 'medium' : nil
      
      if target_spot
        @parking_spots['large'].delete(victim)
        @parking_spots[target_spot] << victim
        update_capacity(target_spot, -1)
        park_car(kar, 'large')
      else
        "No space available"
      end
    else
      "No space available"
    end
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
    return 0.0 if duration_hours.to_f < 0
    return 0.0 if duration_hours.to_f <= 0.25
    
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
    return { success: false, message: "Invalid input" } if plate.to_s.strip.empty? || size.to_s.strip.empty?
    
    normalized_size = size.to_s.downcase
    verdict = @garage.admit_car(plate, normalized_size)

    if verdict.include?('is parked at')
      ticket = ParkingTicket.new(plate, normalized_size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_s = plate.to_s
    ticket = @tix_in_flight[plate_s]
    return { success: false, message: "No active ticket found" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_s)
    
    @tix_in_flight.delete(plate_s)
    { success: true, message: result, fee: fee.to_f, duration_hours: duration }
  end

  def garage_status
    @garage.garage_status
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end