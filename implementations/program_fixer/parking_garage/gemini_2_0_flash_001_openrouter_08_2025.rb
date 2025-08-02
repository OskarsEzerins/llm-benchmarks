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
    license_plate_no = license_plate_no.to_s.strip if license_plate_no
    car_size = car_size.to_s.downcase.strip if car_size

    return "Invalid input" unless license_plate_no && !license_plate_no.empty? &&
                                  ['small', 'medium', 'large'].include?(car_size)

    car = { plate: license_plate_no, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        return "car with license plate no. #{license_plate_no} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{license_plate_no} is parked at large"
      else
        return "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return "car with license plate no. #{license_plate_no} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{license_plate_no} is parked at large"
      else
        return shuffle_medium(car)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{license_plate_no} is parked at large"
      else
        return shuffle_large(car)
      end
    end
    "No space available"
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s.strip if license_plate_no
    return "Invalid input" unless license_plate_no && !license_plate_no.empty?

    small_car  = @parking_spots[:small].find  { |c| c[:plate].to_s == license_plate_no.to_s }
    medium_car = @parking_spots[:medium].find { |c| c[:plate].to_s == license_plate_no.to_s }
    large_car  = @parking_spots[:large].find  { |c| c[:plate].to_s == license_plate_no.to_s }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      return "car with license plate no. #{license_plate_no} exited"
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      return "car with license plate no. #{license_plate_no} exited"
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      return "car with license plate no. #{license_plate_no} exited"
    else
      return "Car not found"
    end
  end

  def shuffle_medium(car)
    if @small > 0
      if @parking_spots[:medium].any?
        victim = @parking_spots[:medium].pop
        @parking_spots[:small] << victim
        @small += 1
        @medium -= 1
        @parking_spots[:medium] << car
        @medium +=1
        return "car with license plate no. #{car[:plate]} is parked at medium"
      elsif @parking_spots[:large].any?
        victim = @parking_spots[:large].pop
          if victim[:size] == 'medium'
            @parking_spots[:small] << victim
            @small += 1
            @large -= 1
            @parking_spots[:large] << car
            @large += 1
            return "car with license plate no. #{car[:plate]} is parked at large"
          else
            return "No space available"
          end
      end
    end
    return "No space available"
  end

  def shuffle_large(car)
    if @medium > 0
      victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      if victim
        @parking_spots[:large].delete(victim)
        @parking_spots[:medium] << victim
        @large -= 1
        @medium += 1
        @parking_spots[:large] << car
        @large += 1
        return "car with license plate no. #{car[:plate]} is parked at large"
      end
    end
    return "No space available"
  end

  def available_spots
    {
      small: @small,
      medium: @medium,
      large: @large
    }
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time   = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.hex(4)}"
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
    return 0.0 unless car_size.is_a?(String) && RATES.keys.include?(car_size) && duration_hours.is_a?(Numeric)

    hours = duration_hours.ceil
    rate  = RATES[car_size]
    total = hours * rate
    [total, MAX_FEE[car_size]].min
  end
end

class ParkingGarageManager
  attr_reader :garage
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    result = garage.admit_car(plate, size)

    if result.include?('parked')
      ticket               = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      return { success: true, message: result, ticket: ticket }
    else
      return { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate = plate.to_s
    ticket = @tix_in_flight[plate]
    return { success: false, message: 'Ticket not found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate)
    return { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  rescue => e
    return { success: false, message: "Error during exit: #{e.message}" }
  end

  def garage_status
    available = garage.available_spots
    occupied = {
      small: garage.parking_spots[:small].size,
      medium: garage.parking_spots[:medium].size,
      large: garage.parking_spots[:large].size
    }
    total_occupied = occupied[:small] + occupied[:medium] + occupied[:large]
    total_available = available[:small] + available[:medium] + available[:large]

    {
      small_available: available[:small],
      medium_available: available[:medium],
      large_available: available[:large],
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end