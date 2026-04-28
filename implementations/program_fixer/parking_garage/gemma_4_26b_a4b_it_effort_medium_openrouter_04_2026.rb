require 'securerandom'

class ParkingGarage
  def initialize(small, medium, large)
    @capacity = {
      'small' => small.to_i,
      'medium' => medium.to_i,
      'large' => large.to_i
    }
    @spots = {
      'small' => [],
      'medium' => [],
      'large' => []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s
    size = car_size.to_s.downcase

    case size
    when 'small'
      if @spots['small'].size < @capacity['small']
        @spots['small'] << { plate: plate, size: size }
        return "car with license plate no. #{plate} is parked at small"
      elsif @spots['medium'].size < @capacity['medium']
        @spots['medium'] << { plate: plate, size: size }
        return "car with license plate no. #{plate} is parked at medium"
      elsif @spots['large'].size < @capacity['large']
        @spots['large'] << { plate: plate, size: size }
        return "car with license plate no. #{plate} is parked at large"
      end
    when 'medium'
      if @spots['medium'].size < @capacity['medium']
        @spots['medium'] << { plate: plate, size: size }
        return "car with license plate no. #{plate} is parked at medium"
      elsif @spots['large'].size < @capacity['large']
        @spots['large'] << { plate: plate, size: size }
        return "car with license plate no. #{plate} is parked at large"
      end
    when 'large'
      if @spots['large'].size < @capacity['large']
        @spots['large'] << { plate: plate, size: size }
        return "car with license plate no. #{plate} is parked at large"
      else
        # Trigger shuffling: move a medium car from a large spot to a medium spot
        medium_victim = @spots['large'].find { |c| c[:size] == 'medium' }
        if medium_victim && @spots['medium'].size < @capacity['medium']
          @spots['large'].delete(medium_victim)
          @spots['medium'] << medium_victim
          @spots['large'] << { plate: plate, size: size }
          return "car with license plate no. #{plate} is parked at large"
        end
      end
    end

    "No space available"
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    target_spot = nil
    car_to_remove = nil

    ['small', 'medium', 'large'].each do |s|
      found = @spots[s].find { |c| c[:plate] == plate }
      if found
        car_to_remove = found
        target_spot = s
        break
      end
    end

    if car_to_remove
      @spots[target_spot].delete(car_to_remove)
      "car with license plate no. #{plate} exited"
    else
      nil
    end
  end

  def status
    s_avail = @capacity['small'] - @spots['small'].size
    m_avail = @capacity['medium'] - @spots['medium'].size
    l_avail = @capacity['large'] - @spots['large'].size
    total_occ = @spots.values.map(&:size).sum
    total_avail = s_avail + m_avail + l_avail
    {
      small_available: s_avail,
      medium_available: m_avail,
      large_available: l_avail,
      total_occupied: total_occ,
      total_available: total_avail
    }
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
    [0.0, (Time.now - @entry_time) / 3600.0].max
  end

  def valid?
    duration_hours < 24
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
    max = MAX_FEE[size] || Float::INFINITY
    
    hours = duration_hours.ceil
    total = hours * rate
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
    plate_str = plate.to_s.strip
    size_str = size.to_s.downcase.strip

    if plate_str.empty? || !['small', 'medium', 'large'].include?(size_str)
      return { success: false, message: "Invalid input" }
    end

    message = @garage.admit_car(plate_str, size_str)

    if message == "No space available"
      { success: false, message: message }
    else
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: message, ticket: ticket }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tix_in_flight[plate_str]
    return { success: false, message: "Car not found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    message = @garage.exit_car(plate_str)

    if message
      @tix_in_flight.delete(plate_str)
      { success: true, message: message, fee: fee, duration_hours: ticket.duration_hours }
    else
      { success: false, message: "Car not found" }
    end
  end

  def garage_status
    @garage.status
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end