require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

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
    license_plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase.strip

    return "Invalid license plate" if license_plate.empty?
    return "Invalid car size" unless %w[small medium large].include?(size)

    car = { plate: license_plate, size: size }

    case size
    when 'small'
      if park_in_spot(car, :small) || park_in_spot(car, :medium) || park_in_spot(car, :large)
        return "car with license plate no. #{license_plate} is parked at #{car[:spot_type]}"
      end
    when 'medium'
      if park_in_spot(car, :medium) || park_in_spot(car, :large)
        return "car with license plate no. #{license_plate} is parked at #{car[:spot_type]}"
      elsif shuffle_medium(car)
        return "car with license plate no. #{license_plate} is parked at #{car[:spot_type]}"
      end
    when 'large'
      if park_in_spot(car, :large)
        return "car with license plate no. #{license_plate} is parked at #{car[:spot_type]}"
      elsif shuffle_large(car)
        return "car with license plate no. #{license_plate} is parked at #{car[:spot_type]}"
      end
    end

    "No space available"
  end

  def exit_car(license_plate_no)
    license_plate = license_plate_no.to_s.strip
    return "Invalid license plate" if license_plate.empty?

    spot_types = %i[small medium large]
    found_spot = nil

    spot_types.each do |spot_type|
      spot_index = @parking_spots[spot_type].index { |car| car[:plate] == license_plate }
      next unless spot_index

      car = @parking_spots[spot_type].delete_at(spot_index)
      found_spot = spot_type
      break
    end

    return "Car not found" unless found_spot

    case found_spot
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end

    "car with license plate no. #{license_plate} exited"
  end

  def available_spots
    {
      small: @small,
      medium: @medium,
      large: @large
    }
  end

  private

  def park_in_spot(car, spot_type)
    available_count = instance_variable_get("@#{spot_type}")
    return false if available_count <= 0

    @parking_spots[spot_type] << car.merge(spot_type: spot_type.to_s)
    instance_variable_set("@#{spot_type}", available_count - 1)
    true
  end

  def shuffle_medium(car)
    return false unless @small > 0

    small_car_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }
    return false unless small_car_in_medium

    @parking_spots[:medium].delete(small_car_in_medium)
    @parking_spots[:small] << small_car_in_medium.merge(spot_type: 'small')
    @small -= 1
    @medium += 1

    park_in_spot(car, :medium)
  end

  def shuffle_large(car)
    return false unless @medium > 0

    medium_car_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    return false unless medium_car_in_large

    @parking_spots[:large].delete(medium_car_in_large)
    @parking_spots[:medium] << medium_car_in_large.merge(spot_type: 'medium')
    @medium -= 1
    @large += 1

    park_in_spot(car, :large)
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase.strip
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24
  end
end

class ParkingFeeCalculator
  RATES = {
    small:  2.0,
    medium: 3.0,
    large:  5.0
  }

  MAX_FEE = {
    small:  20.0,
    medium: 30.0,
    large:  50.0
  }

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase.strip
    return 0.0 unless %w[small medium large].include?(size)
    return 0.0 if duration_hours <= 0.25

    hours = [1, duration_hours.ceil].max
    rate = RATES[size.to_sym]
    total = hours * rate
    [total, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(license_plate, car_size)
    result = @garage.admit_car(license_plate, car_size)
    success = result.include?('parked at')

    if success
      ticket = ParkingTicket.new(license_plate, car_size)
      @tickets[license_plate.to_s.strip] = ticket
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

  def exit_car(license_plate)
    plate = license_plate.to_s.strip
    ticket = @tickets.delete(plate)
    return { success: false, message: "Ticket not found" } unless ticket

    exit_result = @garage.exit_car(plate)
    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)

    {
      success: true,
      message: exit_result,
      fee: fee,
      duration_hours: ticket.duration_hours
    }
  end

  def garage_status
    spots = @garage.available_spots
    total_available = spots[:small] + spots[:medium] + spots[:large]
    total_occupied = (@garage.small + @garage.medium + @garage.large) - total_available

    {
      small_available: spots[:small],
      medium_available: spots[:medium],
      large_available: spots[:large],
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(license_plate)
    @tickets[license_plate.to_s.strip]
  end
end
```