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
      large_spot:   []
    }
  end

  def admit_car(license_plate_no, car_size)
    # Input validation
    return parking_status(nil, nil) if license_plate_no.nil? || car_size.nil?
    license_plate_no = license_plate_no.to_s.strip
    return parking_status(nil, nil) if license_plate_no.empty?
    
    car_size = car_size.to_s.downcase.strip
    valid_sizes = ['small', 'medium', 'large']
    return parking_status(nil, nil) unless valid_sizes.include?(car_size)

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
        parking_status(nil, nil)
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
        parking_status(nil, nil)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status(nil, nil)
      end
    end
  end

  def exit_car(license_plate_no)
    return "No car with license plate #{license_plate_no} found" if license_plate_no.nil?
    license_plate_no = license_plate_no.to_s.strip
    
    car_to_remove = nil
    spot_type = nil

    [:small_spot, :medium_spot, :large_spot].each do |spot_key|
      car = @parking_spots[spot_key].find { |c| c[:plate] == license_plate_no }
      if car
        car_to_remove = car
        spot_type = spot_key
        break
      end
    end

    if car_to_remove
      @parking_spots[spot_type].delete(car_to_remove)
      
      case spot_type
      when :small_spot
        @small += 1
      when :medium_spot
        @medium += 1
      when :large_spot
        @large += 1
      end
      
      "car with license plate no. #{license_plate_no} exited"
    else
      "No car with license plate #{license_plate_no} found"
    end
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase.strip
    @entry_time    = entry_time
  end

  def duration_hours
    return 0.0 if @entry_time.nil?
    ((Time.now - @entry_time) / 3600.0)
  end

  def valid?
    duration_hours <= 24.0
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
    # Input validation
    return 0.0 if car_size.nil? || duration_hours.nil?
    car_size = car_size.to_s.downcase.strip
    return 0.0 unless RATES.key?(car_size)
    return 0.0 if duration_hours.is_a?(String) && duration_hours.to_f.nan?
    duration_hours = duration_hours.to_f
    return 0.0 if duration_hours.nan? || duration_hours < 0

    # Grace period: first 15 minutes (0.25 hours) free
    if duration_hours <= 0.25
      return 0.0
    end
    
    # Round up partial hours to next full hour
    billable_hours = duration_hours.ceil
    
    # Calculate fee
    rate = RATES[car_size]
    total_fee = billable_hours * rate
    
    # Apply daily maximum
    [total_fee, MAX_FEE[car_size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets        = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)
    
    # Extract plate from result if parking was successful
    if result.include?("is parked at")
      plate_str = plate.to_s.strip
      ticket = ParkingTicket.new(plate_str, size)
      @tickets[plate_str] = ticket
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
    plate_str = plate.to_s.strip
    ticket = @tickets[plate_str]
    
    return {
      success: false,
      message: "No car with license plate #{plate_str} found",
      fee: 0.0
    } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)
    
    @tickets.delete(plate_str)
    
    {
      success: true,
      message: result,
      fee: fee,
      duration_hours: ticket.duration_hours.round(2)
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: 3 - (@garage.small + @garage.medium + @garage.large),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end
end