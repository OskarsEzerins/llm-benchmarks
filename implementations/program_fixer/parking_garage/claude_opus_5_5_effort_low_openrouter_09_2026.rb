require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  VALID_SIZES = %w[small medium large].freeze

  def initialize(small, medium, large)
    @small  = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large  = [large.to_i, 0].max

    @parking_spots = {
      small_spot:  [],
      medium_spot: [],
      large_spot:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    return parking_status if license_plate_no.nil? || car_size.nil?
    plate = license_plate_no.to_s.strip
    return parking_status if plate.empty?
    size = car_size.to_s.strip.downcase
    return parking_status unless VALID_SIZES.include?(size)
    return parking_status if find_car(plate)

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
    plate = license_plate_no.to_s.strip
    return exit_status if plate.empty?

    small_car  = @parking_spots[:small_spot].find  { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium_spot].find { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large_spot].find  { |c| c[:plate] == plate }

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

  def shuffle_medium(kar)
    # Move a small car out of a medium or large spot into a free small spot
    return parking_status unless @small > 0

    [:medium_spot, :large_spot].each do |where|
      victim = @parking_spots[where].find { |c| c[:size] == 'small' }
      next unless victim

      @parking_spots[where].delete(victim)
      @parking_spots[:small_spot] << victim
      @small -= 1
      @parking_spots[where] << kar
      return parking_status(kar, where.to_s.sub('_spot', ''))
    end
    parking_status
  end

  def shuffle_large(kar)
    # Move a small/medium car out of a large spot into a free smaller spot
    @parking_spots[:large_spot].each do |victim|
      if victim[:size] == 'small' && @small > 0
        @parking_spots[:large_spot].delete(victim)
        @parking_spots[:small_spot] << victim
        @small -= 1
      elsif %w[small medium].include?(victim[:size]) && @medium > 0
        @parking_spots[:large_spot].delete(victim)
        @parking_spots[:medium_spot] << victim
        @medium -= 1
      else
        next
      end
      @parking_spots[:large_spot] << kar
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
    plate ? "car with license plate no. #{plate} exited" : 'Ticket not found'
  end

  private

  def find_car(plate)
    @parking_spots.values.flatten.find { |c| c[:plate] == plate }
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
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
    "TK-#{SecureRandom.uuid}"
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
    size = car_size.to_s.strip.downcase
    rate = RATES[size]
    return 0.0 unless rate
    return 0.0 unless duration_hours.is_a?(Numeric)
    duration = duration_hours.to_f
    return 0.0 if duration.nan? || duration <= GRACE_PERIOD

    if duration.infinite?
      hours = Float::INFINITY
    else
      hours = duration.ceil
    end
    total = hours * rate
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)

    if result.to_s.include?('is parked at')
      key = plate.to_s.strip
      ticket = ParkingTicket.new(key, size.to_s.strip.downcase)
      @active_tickets[key] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    key = plate.to_s.strip
    ticket = @active_tickets[key]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(key)

    @active_tickets.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @active_tickets.size,
      total_available:  total_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end

  def active_tickets
    @active_tickets.values
  end
end