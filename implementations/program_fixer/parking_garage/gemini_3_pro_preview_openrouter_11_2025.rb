require 'securerandom'
require 'time'

class ParkingGarage
  attr_reader :spots, :allocations

  def initialize(small, medium, large)
    # Total capacities
    @spots = {
      'small'  => [small.to_i, 0].max,
      'medium' => [medium.to_i, 0].max,
      'large'  => [large.to_i, 0].max
    }

    # Currently occupied spots: key is spot_type, value is array of car hashes
    @allocations = {
      'small'  => [],
      'medium' => [],
      'large'  => []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "Invalid input" if license_plate_no.nil? || car_size.nil?
    
    plate = license_plate_no.to_s.strip
    size  = car_size.to_s.downcase.strip
    
    return "Invalid car size" unless %w[small medium large].include?(size)
    return "No space available" if plate.empty?

    # Logic based on car size preference
    case size
    when 'small'
      return parking_success(plate, size, 'small')  if assign_spot(plate, size, 'small')
      return parking_success(plate, size, 'medium') if assign_spot(plate, size, 'medium')
      return parking_success(plate, size, 'large')  if assign_spot(plate, size, 'large')
    when 'medium'
      return parking_success(plate, size, 'medium') if assign_spot(plate, size, 'medium')
      return parking_success(plate, size, 'large')  if assign_spot(plate, size, 'large')
    when 'large'
      if assign_spot(plate, size, 'large')
        return parking_success(plate, size, 'large')
      elsif attempt_shuffle_for_large(plate, size)
        return parking_success(plate, size, 'large')
      end
    end

    "No space available"
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    
    # Find where the car is parked
    spot_type = nil
    car_record = nil

    @allocations.each do |type, cars|
      found = cars.find { |c| c[:plate] == plate }
      if found
        spot_type = type
        car_record = found
        break
      end
    end

    if spot_type && car_record
      @allocations[spot_type].delete(car_record)
      @spots[spot_type] += 1
      "car with license plate no. #{plate} exited"
    else
      "car not found"
    end
  end

  # Status reporting helper
  def current_availability
    {
      small_available:  @spots['small'],
      medium_available: @spots['medium'],
      large_available:  @spots['large'],
      total_occupied:   @allocations.values.map(&:size).sum,
      total_available:  @spots.values.sum
    }
  end

  private

  def assign_spot(plate, car_size, spot_type)
    if @spots[spot_type] > 0
      @allocations[spot_type] << { plate: plate, size: car_size }
      @spots[spot_type] -= 1
      true
    else
      false
    end
  end

  def parking_success(plate, car_size, spot_type)
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  # Logic: If a large spot is needed but full, check if a smaller car is occupying a large spot
  # and if that smaller car can be moved to a smaller spot.
  def attempt_shuffle_for_large(new_plate, new_size)
    # Find a non-large car in a large spot
    movable_car = @allocations['large'].find { |c| c[:size] != 'large' }
    return false unless movable_car

    # Try to move the found car to its appropriate spot or next best
    # Note: A small car in a large spot could go to Small or Medium.
    # A medium car in a large spot could go to Medium.
    moved = false
    target_spot = nil

    if movable_car[:size] == 'small'
      if @spots['small'] > 0
        target_spot = 'small'
      elsif @spots['medium'] > 0
        target_spot = 'medium'
      end
    elsif movable_car[:size] == 'medium'
      if @spots['medium'] > 0
        target_spot = 'medium'
      end
    end

    if target_spot
      # Move the existing car
      @allocations['large'].delete(movable_car)
      @allocations[target_spot] << movable_car
      @spots[target_spot] -= 1
      
      # Logic: We freed a large spot, but we don't increment @spots['large'] 
      # because we immediately consume it for the new car.
      @allocations['large'] << { plate: new_plate, size: new_size }
      true
    else
      false
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size)
    @id            = SecureRandom.uuid
    @license_plate = license_plate
    @car_size      = car_size
    @entry_time    = Time.now
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    # Valid if duration is less than 24 hours
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  HOURLY_RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }

  DAILY_MAX = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || duration_hours.negative?
    
    size = car_size.to_s.downcase
    return 0.0 unless HOURLY_RATES.key?(size)

    # Grace period (15 mins)
    return 0.0 if duration_hours <= 0.25

    # Round up partially used hours
    billable_hours = duration_hours.ceil

    total = billable_hours * HOURLY_RATES[size]
    max   = DAILY_MAX[size]

    [total, max].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    # Data sanitization
    plate_str = plate.to_s.strip
    size_str  = size.to_s.downcase.strip

    verdict = @garage.admit_car(plate_str, size_str)

    if verdict.include?('is parked at')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tix_in_flight[plate_str]
    
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    
    garage_response = @garage.exit_car(plate_str)

    if garage_response.include?('exited')
      @tix_in_flight.delete(plate_str)
      { success: true, message: garage_response, fee: fee, duration_hours: duration.round(2) }
    else
      { success: false, message: garage_response }
    end
  end

  def garage_status
    @garage.current_availability
  end

  # Helper for testing purposes mostly, allows checking active tickets
  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end
end