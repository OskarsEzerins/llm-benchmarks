require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      tiny_spot:   [],
      mid_spot:    [],
      grande_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return { success: false, message: "No space available" } unless valid_input?(license_plate_no, car_size)

    kar = { plate: license_plate_no.to_s, size: car_size.downcase }

    case car_size.downcase
    when 'small'
      if @small > 0
        @parking_spots[:tiny_spot] << kar
        @small -= 1
        return parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return parking_status
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return shuffle_medium(kar)
      end

    when 'large'
      if @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return shuffle_large(kar)
      end
    else
      return { success: false, message: "No space available" }
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s

    small_car  = @parking_spots[:tiny_spot].detect { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:mid_spot].detect { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:grande_spot].detect { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:tiny_spot].delete(small_car)
      @small += 1
      return exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:mid_spot].delete(medium_car)
      @medium += 1
      return exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:grande_spot].delete(large_car)
      @large += 1
      return exit_status(license_plate_no)
    else
      return exit_status
    end
  end

  def shuffle_medium(kar)
    victim = (@parking_spots[:mid_spot] + @parking_spots[:grande_spot]).sample
    return parking_status unless victim

    where = @parking_spots.key(victim) || :mid_spot
    @parking_spots[where].delete(victim)
    @parking_spots[:tiny_spot] << victim
    @small -= 1
    @parking_spots[where] << kar
    parking_status(kar, where.to_s.sub('_spot', ''))
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:grande_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:grande_spot].delete(first_medium)
      @parking_spots[:mid_spot] << first_medium
      @medium -= 1
    end
    @parking_spots[:grande_spot] << kar
    parking_status(kar, 'large')
  end

  def parking_status(car = nil, space = nil)
    if car && space
      { success: true, message: "car with license plate no. #{car[:plate]} is parked at #{space}" }
    else
      { success: false, message: "No space available" }
    end
  end

  def exit_status(plate = nil)
    if plate
      { success: true, message: "car with license plate no. #{plate} exited" }
    else
      { success: false, message: "Ghost car?" }
    end
  end

  private

  def valid_input?(license_plate_no, car_size)
    !license_plate_no.to_s.strip.empty? && ['small', 'medium', 'large'].include?(car_size&.downcase)
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size&.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 23.999
  end
end

class ParkingFeeCalculator
  RATES = {
    small:  2.0,
    medium: 3.0,
    large:  5.0
  }

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= 0.25

    hours = duration_hours.ceil
    rate  = RATES[car_size.downcase]
    total = hours * rate
    [total, MAX_FEE[car_size.downcase]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid input" } unless valid_input?(plate, size)

    verdict = @garage.admit_car(plate, size)

    if verdict[:success]
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate] = ticket
      { success: true, message: verdict[:message], ticket: ticket }
    else
      { success: false, message: verdict[:message] }
    end
  end

  def exit_car(plate)
    ticket = @tix_in_flight[plate]
    return { success: false, message: 'No ticket found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate)
    { success: result[:success], message: result[:message], fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: (@garage.small + @garage.medium + @garage.large) - (@garage.parking_spots[:tiny_spot].size + @garage.parking_spots[:mid_spot].size + @garage.parking_spots[:grande_spot].size),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate]
  end

  private

  def valid_input?(license_plate_no, car_size)
    !license_plate_no.to_s.strip.empty? && ['small', 'medium', 'large'].include?(car_size&.downcase)
  end
end