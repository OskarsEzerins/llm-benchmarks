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
    return 'No space available' if plate.nil? || size.nil?

    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status if plate.nil?

    [:small, :medium, :large].each do |spot|
      car = @parking_spots[spot].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot].delete(car)
      case spot
      when :small  then @small  += 1
      when :medium then @medium += 1
      when :large  then @large  += 1
      end
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(kar)
    # Try to relocate a small car parked in a medium spot to a small spot
    victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
    if victim && @small > 0
      @parking_spots[:medium].delete(victim)
      @parking_spots[:small] << victim
      @small -= 1
      @parking_spots[:medium] << kar
      return parking_status(kar, 'medium')
    end
    parking_status
  end

  def shuffle_large(kar)
    # Try to relocate a medium car parked in a large spot to a medium spot
    victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if victim && @medium > 0
      @parking_spots[:large].delete(victim)
      @parking_spots[:medium] << victim
      @medium -= 1
      @parking_spots[:large] << kar
      return parking_status(kar, 'large')
    end
    parking_status
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      'No car found'
    end
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    s = plate.to_s.strip
    s.empty? ? nil : s
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
    @car_size      = car_size.to_s.strip.downcase
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
    size = car_size.to_s.strip.downcase
    rate = RATES[size]
    return 0.0 if rate.nil?
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours <= 0
    return 0.0 if duration_hours <= GRACE_PERIOD

    hours = duration_hours.ceil
    total = hours * rate
    [total.to_f, MAX_FEE[size]].min
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
      ticket = ParkingTicket.new(plate.to_s, size)
      @active_tickets[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    key    = plate.to_s
    ticket = @active_tickets[key]
    return { success: false, message: 'No active ticket found' } unless ticket

    fee      = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    duration = ticket.duration_hours.round(1)
    result   = @garage.exit_car(plate)

    @active_tickets.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @active_tickets.size,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s]
  end
end