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
    return parking_status unless license_plate_no && !license_plate_no.to_s.strip.empty?
    
    car_size = car_size.to_s.downcase.strip
    return parking_status unless %w[small medium large].include?(car_size)

    kar = { plate: license_plate_no.to_s, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:tiny_spot] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end

    when 'large'
      if @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    plate_str = license_plate_no.to_s
    small_car  = @parking_spots[:tiny_spot].find { |c| c[:plate] == plate_str }
    medium_car = @parking_spots[:mid_spot].find { |c| c[:plate] == plate_str }
    large_car  = @parking_spots[:grande_spot].find { |c| c[:plate] == plate_str }

    if small_car
      @parking_spots[:tiny_spot].delete(small_car)
      @small += 1
      exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:mid_spot].delete(medium_car)
      @medium += 1
      exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:grande_spot].delete(large_car)
      @large += 1
      exit_status(license_plate_no)
    else
      exit_status
    end
  end

  def shuffle_medium(kar)
    medium_cars_in_large = @parking_spots[:grande_spot].select { |c| c[:size] == 'medium' }
    victim = medium_cars_in_large.first
    
    if victim
      @parking_spots[:grande_spot].delete(victim)
      @parking_spots[:mid_spot] << victim
      @parking_spots[:grande_spot] << kar
      @large -= 1
      parking_status(kar, 'large')
    else
      parking_status
    end
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:grande_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:grande_spot].delete(first_medium)
      @parking_spots[:mid_spot] << first_medium
      @parking_spots[:grande_spot] << kar
      @large -= 1
      parking_status(kar, 'large')
    else
      parking_status
    end
  end

  private

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : "No space available"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
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
    return 0.0 if duration_hours.nil? || duration_hours < 0
    return 0.0 if duration_hours <= 0.25
    
    car_size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(car_size)
    
    hours = duration_hours.ceil
    hours = 1 if hours < 1
    rate = RATES[car_size]
    total = hours * rate
    [total, MAX_FEE[car_size]].min.to_f
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "No space available" } if plate.nil? || plate.to_s.strip.empty?
    return { success: false, message: "No space available" } if size.nil? || !%w[small medium large].include?(size.to_s.downcase.strip)
    
    verdict = @garage.admit_car(plate, size)

    if verdict.include?('parked')
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
    return { success: false, message: "No space available" } unless ticket
    return { success: false, message: "No space available" } unless ticket.valid?

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate_str)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    total_spots = @garage.small + @garage.medium + @garage.large
    occupied = @tix_in_flight.size
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: occupied,
      total_available: total_spots
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end