require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots

  def initialize(small, medium, large)
    @parking_spots = {
      'small' => Array.new(small.to_i),
      'medium' => Array.new(medium.to_i),
      'large' => Array.new(large.to_i)
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s
    size = car_size.to_s.downcase

    return "No space available" unless ['small', 'medium', 'large'].include?(size)
    return "No space available" if plate.strip.empty?

    car = { plate: plate, size: size }

    if size == 'small'
      if try_park(car, 'small') || try_park(car, 'medium') || try_park(car, 'large')
        return "car with license plate no. #{plate} is parked at #{find_spot_type(car)}"
      end
    elsif size == 'medium'
      if try_park(car, 'medium') || try_park(car, 'large')
        return "car with license plate no. #{plate} is parked at #{find_spot_type(car)}"
      end
    elsif size == 'large'
      if try_park(car, 'large') || shuffle_for_large(car)
        return "car with license plate no. #{plate} is parked at large"
      end
    end

    "No space available"
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    @parking_spots.each do |type, spots|
      index = spots.find_index { |car| car && car[:plate] == plate }
      if index
        spots[index] = nil
        return "car with license plate no. #{plate} exited"
      end
    end
    "car not found"
  end

  def available_count(type)
    @parking_spots[type].count(nil)
  end

  private

  def try_park(car, type)
    index = @parking_spots[type].find_index(nil)
    if index
      @parking_spots[type][index] = car
      return true
    end
    false
  end

  def find_spot_type(car)
    @parking_spots.find { |type, spots| spots.include?(car) }&.first
  end

  def shuffle_for_large(car)
    # Look for a small or medium car occupying a large spot that can be moved
    @parking_spots['large'].each_with_index do |occupant, index|
      next unless occupant && occupant[:size] != 'large'
      
      # Try to move the occupant to their preferred smaller spot
      if occupant[:size] == 'small'
        if try_park(occupant, 'small') || try_park(occupant, 'medium')
          @parking_spots['large'][index] = car
          return true
        end
      elsif occupant[:size] == 'medium'
        if try_park(occupant, 'medium')
          @parking_spots['large'][index] = car
          return true
        end
      end
    end
    false
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
  RATES = { 'small' => 2.0, 'medium' => 3.0, 'large' => 5.0 }.freeze
  MAX_FEES = { 'small' => 20.0, 'medium' => 30.0, 'large' => 50.0 }.freeze

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 if duration_hours < 0.25
    
    hours = duration_hours.ceil
    fee = hours * RATES[size]
    [fee.to_f, MAX_FEES[size]].min
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
    exit_msg = @garage.exit_car(plate_s)
    
    @tix_in_flight.delete(plate_s)
    { success: true, message: exit_msg, fee: fee.to_f, duration_hours: duration }
  end

  def garage_status
    s = @garage.available_count('small')
    m = @garage.available_count('medium')
    l = @garage.available_count('large')
    total_available = s + m + l
    
    # Total spots are sum of original capacities
    total_capacity = @garage.parking_spots.values.map(&:size).sum
    
    {
      small_available: s,
      medium_available: m,
      large_available: l,
      total_occupied: total_capacity - total_available,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end