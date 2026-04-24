require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small_spot:  [],
      medium_spot: [],
      large_spot:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "No space available" if license_plate_no.nil?
    license_plate_no = license_plate_no.to_s.strip
    return "No space available" if license_plate_no.empty?
    
    car_size = car_size.to_s.downcase.strip if car_size
    return "No space available" unless ['small', 'medium', 'large'].include?(car_size)
    
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
        parking_status
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
        shuffle_medium(kar)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    license_plate_no = license_plate_no.to_s if license_plate_no
    
    small_car  = @parking_spots[:small_spot].detect { |c| c[:plate] == license_plate_no }
    medium_car = @parking_spots[:medium_spot].find  { |c| c[:plate] == license_plate_no }
    large_car  = @parking_spots[:large_spot].find   { |c| c[:plate] == license_plate_no }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      exit_status(license_plate_no)
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      exit_status(license_plate_no)
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      exit_status(license_plate_no)
    else
      exit_status
    end
  end

  def shuffle_medium(kar)
    small_in_medium = @parking_spots[:medium_spot].find { |c| c[:size] == 'small' }
    if small_in_medium && @small > 0
      @parking_spots[:medium_spot].delete(small_in_medium)
      @parking_spots[:small_spot] << small_in_medium
      @small -= 1
      @parking_spots[:medium_spot] << kar
      parking_status(kar, 'medium')
    else
      parking_status
    end
  end

  def shuffle_large(kar)
    medium_in_large = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium > 0
      @parking_spots[:large_spot].delete(medium_in_large)
      @parking_spots[:medium_spot] << medium_in_large
      @medium -= 1
      @parking_spots[:large_spot] << kar
      parking_status(kar, 'large')
    else
      parking_status
    end
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      "Car not found"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size ? car_size.to_s.downcase.strip : nil
    @entry_time    = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24
  end

  private

  def generate_ticket_id
    "TK-#{rand(9999)}"
  end
end

class ParkingFeeCalculator
  RATES = {
    small:  2.0,
    medium: 3.0,
    large:  5.0
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    begin
      duration_hours = Float(duration_hours)
    rescue TypeError, ArgumentError
      return 0.0
    end
    
    return 0.0 if duration_hours < 0
    return 0.0 if car_size.nil?
    
    car_size = car_size.to_s.downcase.strip
    return 0.0 unless RATES.key?(car_size.to_sym)
    
    return 0.0 if duration_hours <= GRACE_PERIOD
    
    hours = duration_hours.ceil
    
    rate  = RATES[car_size.to_sym]
    total = hours * rate
    
    [total, MAX_FEE[car_size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @tix_in_flight   = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid input" } if plate.nil?
    plate = plate.to_s.strip
    return { success: false, message: "Invalid input" } if plate.empty?
    
    size = size.to_s.downcase.strip if size
    return { success: false, message: "Invalid input" } unless ['small', 'medium', 'large'].include?(size)

    verdict = @garage.admit_car(plate, size)

    if verdict.include?('parked')
      ticket                = ParkingTicket.new(plate, size)
      @tix_in_flight[plate] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate = plate.to_s if plate
    ticket = @tix_in_flight[plate]
    return { success: false, message: "Car not found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    @tix_in_flight.delete(plate)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large
    total_occupied = @tix_in_flight.size
    
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   total_occupied,
      total_available:  total_available
    }
  end

  def find_ticket(plate)
    plate = plate.to_s if plate
    @tix_in_flight[plate]
  end

  private

  def garage
    @garage
  end
end