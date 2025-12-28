require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @total_small  = small.to_i
    @total_medium = medium.to_i
    @total_large  = large.to_i
    @small  = @total_small
    @medium = @total_medium
    @large  = @total_large
    @parking_spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size  = car_size.to_s.downcase

    return "Invalid license plate" if plate.empty?
    return "Invalid car size" unless %w[small medium large].include?(size)

    case size
    when 'small'
      admit_small_car(plate)
    when 'medium'
      admit_medium_car(plate)
    when 'large'
      admit_large_car(plate)
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    car = nil
    spot_type = nil

    [:small, :medium, :large].each do |type|
      car = @parking_spots[type].find { |c| c[:plate] == plate }
      if car
        spot_type = type
        break
      end
    end

    if car
      @parking_spots[spot_type].delete(car)
      case spot_type
      when :small  then @small  += 1
      when :medium then @medium += 1
      when :large  then @large  += 1
      end
      "car with license plate no. #{plate} exited"
    else
      "car with license plate no. #{plate} not found"
    end
  end

  def occupied_spots
    @parking_spots.values.sum(&:size)
  end

  private

  def success_msg(plate, spot_type)
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def no_space_msg
    "No space available"
  end

  def admit_small_car(plate)
    if @small > 0
      park_in(plate, 'small', :small)
      success_msg(plate, 'small')
    elsif @medium > 0
      park_in(plate, 'small', :medium)
      success_msg(plate, 'medium')
    elsif @large > 0
      park_in(plate, 'small', :large)
      success_msg(plate, 'large')
    else
      no_space_msg
    end
  end

  def admit_medium_car(plate)
    if @medium > 0
      park_in(plate, 'medium', :medium)
      success_msg(plate, 'medium')
    elsif @large > 0
      park_in(plate, 'medium', :large)
      success_msg(plate, 'large')
    elsif attempt_shuffle_for_medium(plate)
      success_msg(plate, 'medium')
    else
      no_space_msg
    end
  end

  def admit_large_car(plate)
    if @large > 0
      park_in(plate, 'large', :large)
      success_msg(plate, 'large')
    elsif attempt_shuffle_for_large(plate)
      success_msg(plate, 'large')
    else
      no_space_msg
    end
  end

  def park_in(plate, size, spot_type)
    car = { plate: plate.to_s, size: size }
    @parking_spots[spot_type] << car
    case spot_type
    when :small  then @small  -= 1
    when :medium then @medium -= 1
    when :large  then @large  -= 1
    end
  end

  def find_car_of_size_in_spot(size, spot_type)
    @parking_spots[spot_type].find { |car| car[:size] == size }
  end

  def move_car(car, from_type, to_type)
    @parking_spots[from_type].delete(car)
    @parking_spots[to_type] << car

    case from_type
    when :small  then @small  += 1
    when :medium then @medium += 1
    when :large  then @large  += 1
    end

    case to_type
    when :small  then @small  -= 1
    when :medium then @medium -= 1
    when :large  then @large  -= 1
    end
  end

  def attempt_shuffle_for_medium(plate)
    return false unless @small > 0

    small_car_in_medium = find_car_of_size_in_spot('small', :medium)
    return false unless small_car_in_medium

    move_car(small_car_in_medium, :medium, :small)
    park_in(plate, 'medium', :medium)
    true
  end

  def attempt_shuffle_for_large(plate)
    if @medium > 0
      medium_car_in_large = find_car_of_size_in_spot('medium', :large)
      if medium_car_in_large
        move_car(medium_car_in_large, :large, :medium)
        park_in(plate, 'large', :large)
        return true
      end
    end

    if @small > 0
      small_car_in_medium = find_car_of_size_in_spot('small', :medium)
      medium_car_in_large = find_car_of_size_in_spot('medium', :large)
      if small_car_in_medium && medium_car_in_large
        move_car(small_car_in_medium, :medium, :small)
        move_car(medium_car_in_large, :large, :medium)
        park_in(plate, 'large', :large)
        return true
      end
    end

    false
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(2)
  end

  def valid?
    duration_hours < 24
  end
end

class ParkingFeeCalculator
  RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || duration_hours < 0

    size = car_size.to_s.downcase
    rate = RATES[size]
    return 0.0 unless rate

    effective = duration_hours - GRACE_PERIOD
    return 0.0 if effective <= 0

    hours = effective.ceil
    total = hours * rate

    max = MAX_FEE[size] || 0.0
    total > max ? max : total
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str  = size.to_s.downcase

    message = @garage.admit_car(plate_str, size_str)

    if message.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tix_in_flight[plate_str]

    unless ticket
      return { success: false, message: "Ticket not found for plate #{plate_str}" }
    end

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    exit_message = @garage.exit_car(plate_str)

    @tix_in_flight.delete(plate_str)

    {
      success: true,
      message: exit_message,
      fee: fee.to_f,
      duration_hours: ticket.duration_hours
    }
  end

  def garage_status
    small_avail  = @garage.small
    medium_avail = @garage.medium
    large_avail  = @garage.large
    occupied     = @garage.occupied_spots
    total_avail  = small_avail + medium_avail + large_avail

    {
      small_available:  small_avail,
      medium_available: medium_avail,
      large_available:  large_avail,
      total_occupied:   occupied,
      total_available:  total_avail
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end
end