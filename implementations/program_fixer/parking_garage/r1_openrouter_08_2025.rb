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
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "No space available" unless valid_plate?(license_plate_no) && valid_size?(car_size)

    car_size = car_size.downcase
    kar = { plate: license_plate_no.to_s.strip, size: car_size }

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
        "No space available"
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
        shuffle_medium(kar) ? parking_status(kar, 'medium') : "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar) ? parking_status(kar, 'large') : "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    small_car  = @parking_spots[:small_spot].find   { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium_spot].find  { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large_spot].find   { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      "car with license plate no. #{plate} exited"
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      "car with license plate no. #{plate} exited"
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      "car with license plate no. #{plate} exited"
    else
      "Ghost car?"
    end
  end

  def shuffle_medium(kar)
    victim = (@parking_spots[:medium_spot] + @parking_spots[:large_spot]).find { |c| c[:size] == 'medium' }
    return false unless victim

    if victim[:size] == 'medium' && @medium > 0
      @parking_spots[:medium_spot].delete(victim)
      @medium += 1
      @parking_spots[:medium_spot] << kar
      true
    else
      false
    end
  end

  def shuffle_large(kar)
    victim = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if victim && @medium > 0
      @parking_spots[:large_spot].delete(victim)
      @medium -= 1
      @parking_spots[:medium_spot] << victim
      @parking_spots[:large_spot] << kar
      true
    else
      false
    end
  end

  def parking_status(car = nil, space = nil)
    { success: true, message: "car with license plate no. #{car[:plate]} is parked at #{space}" }
  end

  private

  def valid_plate?(plate)
    plate.to_s.strip != ""
  end

  def valid_size?(size)
    %w[small medium large].include?(size.to_s.downcase)
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - entry_time).to_f / 3600
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = { small: 2.0, medium: 3.0, large: 5.0 }
  MAX_FEE = { 'small' => 20.0, 'medium' => 30.0, 'large' => 50.0 }

  def calculate_fee(car_size, duration_hours)
    return 0.0 unless duration_hours.is_a?(Numeric) && duration_hours >= 0

    car_size = car_size.downcase
    return 0.0 unless MAX_FEE.key?(car_size)

    adjusted = duration_hours - 0.25
    return 0.0 if adjusted <= 0

    hours = adjusted.ceil
    rate = RATES[car_size.to_sym]
    total = hours * rate
    [total, MAX_FEE[car_size]].min
  rescue
    0.0
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    return invalid_response unless valid_inputs?(plate, size)

    plate_str = plate.to_s.strip
    size_str = size.to_s.downcase
    result = @garage.admit_car(plate_str, size_str)

    if result.is_a?(Hash) && result[:success]
      ticket = ParkingTicket.new(plate_str, size_str)
      @tickets[plate_str] = ticket
      { success: true, message: result[:message], ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tickets[plate_str]
    return { success: false, message: 'Invalid ticket' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)
    @tickets.delete(plate_str)

    { success: true, message: result, fee: fee.round(1), duration_hours: ticket.duration_hours.round(1) }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: (@garage.small + @garage.medium + @garage.large),
      total_available: (@garage.small + @garage.medium + @garage.large)
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s.strip]
  end

  private

  def valid_inputs?(plate, size)
    plate.to_s.strip != "" && %w[small medium large].include?(size.to_s.downcase)
  end

  def invalid_response
    { success: false, message: 'Invalid license plate or car size' }
  end
end