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
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase.strip
    return "No space available" if plate.empty? || !['small', 'medium', 'large'].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        park_car(car, 'small')
      elsif @medium > 0
        park_car(car, 'medium')
      elsif @large > 0
        park_car(car, 'large')
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        park_car(car, 'medium')
      elsif @large > 0
        park_car(car, 'large')
      else
        shuffle_for_medium(car)
      end
    when 'large'
      if @large > 0
        park_car(car, 'large')
      else
        shuffle_for_large(car)
      end
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    return "Car not found" if plate.empty?

    @parking_spots.each do |type, cars|
      car = cars.find { |c| c[:plate] == plate }
      if car
        cars.delete(car)
        update_count(type, 1)
        return "car with license plate no. #{plate} exited"
      end
    end
    "Car not found"
  end

  private

  def park_car(car, spot_type)
    @parking_spots[spot_type] << car
    update_count(spot_type, -1)
    "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
  end

  def update_count(type, delta)
    case type
    when 'small'  then @small += delta
    when 'medium' then @medium += delta
    when 'large'  then @large += delta
    end
  end

  def shuffle_for_medium(car)
    # Medium car can't shuffle into small, only needs large.
    # But the logic provided in requirements is strict.
    "No space available"
  end

  def shuffle_for_large(car)
    # If large car needs space, try to move a medium car from a large spot to a medium spot
    victim = @parking_spots['large'].find { |c| c[:size] == 'medium' }
    if victim && @medium > 0
      @parking_spots['large'].delete(victim)
      @parking_spots['medium'] << victim
      @medium -= 1
      
      @parking_spots['large'] << car
      # @large remains 0 because we replaced one car with another
      return "car with license plate no. #{car[:plate]} is parked at large"
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
    return 0.0 if duration_hours <= 0.25
    
    size = car_size.to_s.downcase
    rate = RATES[size] || 0.0
    max = MAX_FEE[size] || 0.0
    
    fee = duration_hours.ceil * rate
    [fee.to_f, max.to_f].min
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    res = @garage.admit_car(plate, size)
    if res.start_with?("car with license plate")
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: res, ticket: ticket }
    else
      { success: false, message: res }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tix_in_flight[plate_str]
    return { success: false, message: "Ticket not found" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    res = @garage.exit_car(plate_str)
    
    @tix_in_flight.delete(plate_str)
    { success: true, message: res, fee: fee.to_f, duration_hours: duration }
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