require 'securerandom'

class ParkingGarage
  attr_reader :available, :occupied

  def initialize(small, medium, large)
    @available = {
      'small'  => small.to_i,
      'medium' => medium.to_i,
      'large'  => large.to_i
    }
    @occupied = {
      'small'  => [],
      'medium' => [],
      'large'  => []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase
    return "No space available" if plate.empty? || !['small', 'medium', 'large'].include?(size)

    case size
    when 'small'
      if @available['small'] > 0
        park(plate, 'small', 'small')
      elsif @available['medium'] > 0
        park(plate, 'small', 'medium')
      elsif @available['large'] > 0
        park(plate, 'small', 'large')
      else
        "No space available"
      end
    when 'medium'
      if @available['medium'] > 0
        park(plate, 'medium', 'medium')
      elsif @available['large'] > 0
        park(plate, 'medium', 'large')
      else
        "No space available"
      end
    when 'large'
      if @available['large'] > 0
        park(plate, 'large', 'large')
      else
        attempt_shuffle_for_large(plate)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    @occupied.each do |type, cars|
      car = cars.find { |c| c[:plate] == plate }
      if car
        cars.delete(car)
        @available[type] += 1
        return "car with license plate no. #{plate} exited"
      end
    end
    "No such car found"
  end

  private

  def park(plate, original_size, spot_type)
    @occupied[spot_type] << { plate: plate, size: original_size }
    @available[spot_type] -= 1
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def attempt_shuffle_for_large(plate)
    # Try to move a medium car from large to medium
    target_med = @occupied['large'].find { |c| c[:size] == 'medium' }
    if target_med && @available['medium'] > 0
      @occupied['large'].delete(target_med)
      @available['large'] += 1
      @occupied['medium'] << target_med
      @available['medium'] -= 1
      park(plate, 'large', 'large')
    else
      # Try to move a small car from large to small or medium
      target_small = @occupied['large'].find { |c| c[:size] == 'small' }
      if target_small && (@available['small'] > 0 || @available['medium'] > 0)
        @occupied['large'].delete(target_small)
        @available['large'] += 1
        if @available['small'] > 0
          @occupied['small'] << target_small
          @available['small'] -= 1
        else
          @occupied['medium'] << target_small
          @available['medium'] -= 1
        end
        park(plate, 'large', 'large')
      else
        "No space available"
      end
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = "TK-#{SecureRandom.uuid}"
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
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
    return 0.0 if duration_hours <= 0.25
    
    size = car_size.to_s.downcase
    rate = RATES[size] || 0.0
    max = MAX_FEE[size] || Float::INFINITY
    
    total = duration_hours.ceil * rate
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
    verdict = @garage.admit_car(plate, size)

    if verdict.include?("parked")
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket = @tix_in_flight[plate_str]
    return { success: false, message: "No such car found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result_msg = @garage.exit_car(plate_str)

    if result_msg.include?("exited")
      @tix_in_flight.delete(plate_str)
      { success: true, message: result_msg, fee: fee.to_f, duration_hours: ticket.duration_hours.to_f }
    else
      { success: false, message: result_msg }
    end
  end

  def garage_status
    occupied_count = @garage.occupied.values.map(&:size).sum
    available_count = @garage.available.values.sum
    {
      small_available: @garage.available['small'],
      medium_available: @garage.available['medium'],
      large_available: @garage.available['large'],
      total_occupied: occupied_count,
      total_available: available_count
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end