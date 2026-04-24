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
    return "No space available" if license_plate_no.nil?
    plate = license_plate_no.to_s.strip
    return "No space available" if plate.empty?
    return "No space available" if car_size.nil?

    size = car_size.to_s.downcase.strip
    return "No space available" unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        parking_status(plate, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(plate, 'large')
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(plate, 'large')
      else
        "No space available"
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(plate, 'large')
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    return "car not found" if license_plate_no.nil?
    plate = license_plate_no.to_s

    [:small, :medium, :large].each do |spot_type|
      car = @parking_spots[spot_type].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot_type].delete(car)
      case spot_type
      when :small  then @small  += 1
      when :medium then @medium += 1
      when :large  then @large  += 1
      end
      return "car with license plate no. #{plate} exited"
    end

    "car with license plate no. #{plate} not found"
  end

  private

  def shuffle_large(car)
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_in_large && @medium > 0
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium -= 1
      @parking_spots[:large] << car
      return parking_status(car[:plate], 'large')
    end

    small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if small_in_large
      if @small > 0
        @parking_spots[:large].delete(small_in_large)
        @parking_spots[:small] << small_in_large
        @small -= 1
        @parking_spots[:large] << car
        return parking_status(car[:plate], 'large')
      elsif @medium > 0
        @parking_spots[:large].delete(small_in_large)
        @parking_spots[:medium] << small_in_large
        @medium -= 1
        @parking_spots[:large] << car
        return parking_status(car[:plate], 'large')
      end
    end

    "No space available"
  end

  def parking_status(plate, spot_type)
    "car with license plate no. #{plate} is parked at #{spot_type}"
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
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if car_size.nil? || duration_hours.nil?
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours <= GRACE_PERIOD

    billable = duration_hours - GRACE_PERIOD
    hours = billable.ceil
    total = (hours * RATES[size]).to_f
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)

    if result.to_s.include?('parked')
      plate_key = plate.to_s.strip
      ticket = ParkingTicket.new(plate_key, size)
      @active_tickets[plate_key] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_key = plate.to_s.strip
    ticket = @active_tickets[plate_key]
    return { success: false, message: "No active ticket for #{plate_key}" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_key)
    @active_tickets.delete(plate_key)

    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    small_avail  = @garage.small
    medium_avail = @garage.medium
    large_avail  = @garage.large
    total_avail  = small_avail + medium_avail + large_avail

    {
      small_available:  small_avail,
      medium_available: medium_avail,
      large_available:  large_avail,
      total_occupied:   @active_tickets.size,
      total_available:  total_avail
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end