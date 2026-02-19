require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @initial_small  = small.to_i
    @initial_medium = medium.to_i
    @initial_large  = large.to_i
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
    return "No space available" if license_plate_no.nil? || car_size.nil?
    
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase.strip
    
    return "No space available" if plate.empty?
    return "No space available" unless ['small', 'medium', 'large'].include?(size)
    
    kar = { plate: plate, size: size }

    case size
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
    return exit_status if license_plate_no.nil?
    
    plate = license_plate_no.to_s
    
    small_car  = @parking_spots[:small_spot].find { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium_spot].find { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large_spot].find { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      exit_status(plate)
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      exit_status(plate)
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      exit_status(plate)
    else
      exit_status
    end
  end

  def total_occupied
    (@initial_small - @small) + (@initial_medium - @medium) + (@initial_large - @large)
  end

  def total_available
    @small + @medium + @large
  end

  private

  def shuffle_medium(kar)
    small_in_medium = @parking_spots[:medium_spot].find { |c| c[:size] == 'small' }
    
    if small_in_medium && @small > 0
      @parking_spots[:medium_spot].delete(small_in_medium)
      @parking_spots[:small_spot] << small_in_medium
      @small -= 1
      @medium += 1
      @parking_spots[:medium_spot] << kar
      @medium -= 1
      parking_status(kar, 'medium')
    else
      small_in_large = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
      if small_in_large && (@small > 0 || @medium > 0)
        @parking_spots[:large_spot].delete(small_in_large)
        if @small > 0
          @parking_spots[:small_spot] << small_in_large
          @small -= 1
        else
          @parking_spots[:medium_spot] << small_in_large
          @medium -= 1
        end
        @large += 1
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end
    end
  end

  def shuffle_large(kar)
    medium_in_large = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    
    if medium_in_large && @medium > 0
      @parking_spots[:large_spot].delete(medium_in_large)
      @parking_spots[:medium_spot] << medium_in_large
      @medium -= 1
      @large += 1
      @parking_spots[:large_spot] << kar
      @large -= 1
      parking_status(kar, 'large')
    else
      small_in_large = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
      
      if small_in_large && (@small > 0 || @medium > 0)
        @parking_spots[:large_spot].delete(small_in_large)
        
        if @small > 0
          @parking_spots[:small_spot] << small_in_large
          @small -= 1
        else
          @parking_spots[:medium_spot] << small_in_large
          @medium -= 1
        end
        
        @large += 1
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end
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
    @car_size      = car_size.to_s.downcase
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
  }

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || car_size.nil?
    
    size = car_size.to_s.downcase
    duration = duration_hours.to_f
    
    return 0.0 if duration < 0
    return 0.0 unless ['small', 'medium', 'large'].include?(size)
    return 0.0 if duration <= GRACE_PERIOD
    
    hours = duration.ceil
    rate = RATES[size.to_sym]
    total = hours * rate
    
    [total, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @tix_in_flight   = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "Invalid input" } if plate.nil? || size.nil?
    
    plate_str = plate.to_s.strip
    size_str = size.to_s.downcase.strip
    
    return { success: false, message: "Invalid license plate" } if plate_str.empty?
    return { success: false, message: "Invalid car size" } unless ['small', 'medium', 'large'].include?(size_str)
    
    verdict = @garage.admit_car(plate_str, size_str)

    if verdict.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    return { success: false, message: "Invalid license plate" } if plate.nil?
    
    plate_str = plate.to_s
    ticket = @tix_in_flight[plate_str]
    
    return { success: false, message: "No active ticket found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)

    @tix_in_flight.delete(plate_str)
    
    { 
      success: true, 
      message: result, 
      fee: fee, 
      duration_hours: ticket.duration_hours 
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.total_occupied,
      total_available: @garage.total_available
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?
    @tix_in_flight[plate.to_s]
  end
end