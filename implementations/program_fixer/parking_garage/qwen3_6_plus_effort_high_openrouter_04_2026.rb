require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return false if license_plate_no.nil? || car_size.nil?
    
    plate_str = license_plate_no.to_s.strip
    return false if plate_str.empty?
    
    size_str = car_size.to_s.downcase.strip
    return false unless %w[small medium large].include?(size_str)

    assigned_spot = nil

    case size_str
    when 'small'
      if @small > 0
        assigned_spot = :small
        @small -= 1
      elsif @medium > 0
        assigned_spot = :medium
        @medium -= 1
      elsif @large > 0
        assigned_spot = :large
        @large -= 1
      end
    when 'medium'
      if @medium > 0
        assigned_spot = :medium
        @medium -= 1
      elsif @large > 0
        assigned_spot = :large
        @large -= 1
      end
    when 'large'
      if @large > 0
        assigned_spot = :large
        @large -= 1
      end
    end

    if assigned_spot
      @parking_spots[assigned_spot] << { plate: plate_str, size: size_str }
      "car with license plate no. #{plate_str} is parked at #{assigned_spot}"
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate_str = license_plate_no.to_s.strip
    
    found_spot_type = nil
    car_record = nil

    [:small, :medium, :large].each do |spot|
      idx = @parking_spots[spot].index { |c| c[:plate] == plate_str }
      if idx
        found_spot_type = spot
        car_record = @parking_spots[spot].delete_at(idx)
        break
      end
    end

    if found_spot_type
      if found_spot_type == :small
        @small += 1
      elsif found_spot_type == :medium
        @medium += 1
      elsif found_spot_type == :large
        @large += 1
      end
      "car with license plate no. #{plate_str} exited"
    else
      "car not found"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase.strip
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24
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
    return 0.0 if car_size.nil? || duration_hours.nil?
    
    size = car_size.to_s.downcase.strip
    hours = duration_hours.to_f
    
    return 0.0 unless RATES.key?(size)
    return 0.0 if hours < 0

    # Grace period: First 15 minutes (0.25 hours) free
    if hours <= 0.25
      return 0.0
    end

    # Round up partial hours to next full hour
    billable_hours = hours.ceil
    
    rate = RATES[size]
    total = billable_hours * rate
    
    max = MAX_FEE[size]
    [total, max].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)
    
    if result.is_a?(String) && result.include?("is parked at")
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      msg = result.is_a?(String) ? result : "Admission failed"
      { success: false, message: msg }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tickets[plate_str]
    
    unless ticket && ticket.valid?
      return { success: false, message: "Invalid ticket or car not found" }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    exit_result = @garage.exit_car(plate)
    
    @tickets.delete(plate_str)
    
    success = exit_result.to_s.include?("exited")
    
    { 
      success: success, 
      message: exit_result, 
      fee: fee, 
      duration_hours: ticket.duration_hours 
    }
  end

  def garage_status
    available = @garage.small + @garage.medium + @garage.large
    occupied = @garage.parking_spots.values.map(&:size).sum
    
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: occupied,
      total_available: available
    }
  end
end