require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :available

  def initialize(small, medium, large)
    @available = {
      small: small.to_i,
      medium: medium.to_i,
      large: large.to_i
    }

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def small
    @available[:small]
  end

  def medium
    @available[:medium]
  end

  def large
    @available[:large]
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)

    return no_space if plate.empty? || size.nil?

    case size
    when 'small'
      park_small(plate, size)
    when 'medium'
      park_medium(plate, size)
    when 'large'
      park_large(plate, size)
    else
      no_space
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)

    @parking_spots.each do |spot_type, cars|
      car = cars.find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot_type].delete(car)
      @available[spot_type] += 1
      return "car with license plate no. #{plate} exited"
    end

    "No car found"
  end

  private

  def normalize_plate(plate)
    plate.to_s.strip
  end

  def normalize_size(size)
    size.to_s.downcase.strip
  end

  def no_space
    "No space available"
  end

  def parked_message(plate, spot_type)
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def occupy(spot_type, plate, size)
    return no_space unless @available[spot_type] > 0

    @parking_spots[spot_type] << { plate: plate, size: size }
    @available[spot_type] -= 1
    parked_message(plate, spot_type.to_s)
  end

  def park_small(plate, size)
    if @available[:small] > 0
      occupy(:small, plate, size)
    elsif @available[:medium] > 0
      occupy(:medium, plate, size)
    elsif @available[:large] > 0
      occupy(:large, plate, size)
    else
      no_space
    end
  end

  def park_medium(plate, size)
    if @available[:medium] > 0
      occupy(:medium, plate, size)
    elsif @available[:large] > 0
      occupy(:large, plate, size)
    else
      no_space
    end
  end

  def park_large(plate, size)
    if @available[:large] > 0
      occupy(:large, plate, size)
    else
      shuffle_large(plate, size)
    end
  end

  def shuffle_large(plate, size)
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }

    if medium_in_large && @available[:medium] > 0
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @available[:medium] -= 1
      @available[:large] += 1

      occupy(:large, plate, size)
    else
      no_space
    end
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
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = {
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }.freeze

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)

    duration = Float(duration_hours) rescue nil
    return 0.0 if duration.nil? || duration < 0.0

    return 0.0 if duration <= 0.25

    hours = duration.ceil
    total = hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str = size.to_s.downcase.strip

    if plate_str.empty? || !%w[small medium large].include?(size_str)
      return { success: false, message: "No space available" }
    end

    result = @garage.admit_car(plate_str, size_str)

    if result.include?("is parked at")
      ticket = ParkingTicket.new(plate_str, size_str)
      @active_tickets[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @active_tickets[plate_str]

    return { success: false, message: "No active ticket found" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)

    @active_tickets.delete(plate_str)

    {
      success: true,
      message: result,
      fee: fee,
      duration_hours: ticket.duration_hours
    }
  end

  def garage_status
    total_occupied = @garage.parking_spots.values.sum(&:size)
    total_available = @garage.available.values.sum

    {
      small_available: @garage.available[:small],
      medium_available: @garage.available[:medium],
      large_available: @garage.available[:large],
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end