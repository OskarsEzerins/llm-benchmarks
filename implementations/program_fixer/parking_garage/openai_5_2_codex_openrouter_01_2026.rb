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
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)
    return "No space available" unless plate && size

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        return parking_message(plate, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return parking_message(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return parking_message(plate, 'large')
      else
        return "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return parking_message(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return parking_message(plate, 'large')
      else
        result = shuffle_for_medium(car)
        return result || "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return parking_message(plate, 'large')
      else
        result = shuffle_for_large(car)
        return result || "No space available"
      end
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return "Car not found" unless plate

    [:small, :medium, :large].each do |spot|
      car = @parking_spots[spot].find { |c| c[:plate] == plate }
      if car
        @parking_spots[spot].delete(car)
        case spot
        when :small
          @small += 1
        when :medium
          @medium += 1
        when :large
          @large += 1
        end
        return exit_message(plate)
      end
    end

    "Car not found"
  end

  private

  def shuffle_for_medium(car)
    return nil unless @small > 0
    small_car = @parking_spots[:large].find { |c| c[:size] == 'small' }
    return nil unless small_car

    move_from_large(small_car, :small)
    @parking_spots[:large] << car
    @large -= 1
    parking_message(car[:plate], 'large')
  end

  def shuffle_for_large(car)
    if @medium > 0
      medium_car = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      if medium_car
        move_from_large(medium_car, :medium)
        @parking_spots[:large] << car
        @large -= 1
        return parking_message(car[:plate], 'large')
      end
    end

    if @small > 0
      small_car = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_car
        move_from_large(small_car, :small)
        @parking_spots[:large] << car
        @large -= 1
        return parking_message(car[:plate], 'large')
      end
    end

    if @medium > 0
      small_car = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_car
        move_from_large(small_car, :medium)
        @parking_spots[:large] << car
        @large -= 1
        return parking_message(car[:plate], 'large')
      end
    end

    nil
  end

  def move_from_large(car, target)
    @parking_spots[:large].delete(car)
    @parking_spots[target] << car
    @large += 1
    @small -= 1 if target == :small
    @medium -= 1 if target == :medium
  end

  def parking_message(plate, spot)
    "car with license plate no. #{plate} is parked at #{spot}"
  end

  def exit_message(plate)
    "car with license plate no. #{plate} exited"
  end

  def normalize_plate(plate)
    return nil if plate.nil?
    str = plate.to_s.strip
    return nil if str.empty?
    str
  end

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    %w[small medium large].include?(s) ? s : nil
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    rate = RATES[size]
    return 0.0 unless rate
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours < 0

    return 0.0 if duration_hours <= GRACE_PERIOD

    hours = duration_hours.ceil
    total = hours * rate
    max_fee = MAX_FEE[size] || total
    total > max_fee ? max_fee.to_f : total.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @active_tickets  = {}
  end

  def admit_car(plate, size)
    plate_str = normalize_plate(plate)
    size_str  = normalize_size(size)
    return { success: false, message: 'Invalid input' } unless plate_str && size_str

    if @active_tickets.key?(plate_str)
      return { success: false, message: 'Car already parked' }
    end

    message = @garage.admit_car(plate_str, size_str)
    if message != "No space available"
      ticket = ParkingTicket.new(plate_str, size_str)
      @active_tickets[plate_str] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    plate_str = normalize_plate(plate)
    return { success: false, message: 'Invalid input' } unless plate_str

    ticket = @active_tickets[plate_str]
    return { success: false, message: 'Ticket not found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    message = @garage.exit_car(plate_str)
    @active_tickets.delete(plate_str)
    { success: true, message: message, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    total_occupied = @garage.parking_spots.values.map(&:size).reduce(0, :+)
    total_available = @garage.small + @garage.medium + @garage.large
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    plate_str = normalize_plate(plate)
    return nil unless plate_str
    @active_tickets[plate_str]
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?
    str = plate.to_s.strip
    return nil if str.empty?
    str
  end

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    %w[small medium large].include?(s) ? s : nil
  end
end