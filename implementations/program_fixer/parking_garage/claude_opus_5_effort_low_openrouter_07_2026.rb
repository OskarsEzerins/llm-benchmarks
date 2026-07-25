require 'securerandom'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :parking_spots, :small, :medium, :large

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
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)

    return parking_status if plate.nil? || size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_medium(car)
      end
    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car)
      end
    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status if plate.nil?

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

  # A medium car needs a spot: try moving a small car out of a medium spot
  # into an available small spot.
  def shuffle_medium(car)
    movable = @parking_spots[:medium_spot].find { |c| c[:size] == 'small' }

    if movable && @small > 0
      @parking_spots[:medium_spot].delete(movable)
      @parking_spots[:small_spot] << movable
      @small -= 1
      @parking_spots[:medium_spot] << car
      return parking_status(car, 'medium')
    end

    parking_status
  end

  # A large car needs a large spot: try relocating a smaller car occupying a
  # large spot into an appropriate smaller free spot.
  def shuffle_large(car)
    movable = @parking_spots[:large_spot].find do |c|
      (c[:size] == 'medium' && @medium > 0) || (c[:size] == 'small' && (@small > 0 || @medium > 0))
    end

    if movable
      @parking_spots[:large_spot].delete(movable)
      if movable[:size] == 'medium'
        @parking_spots[:medium_spot] << movable
        @medium -= 1
      elsif @small > 0
        @parking_spots[:small_spot] << movable
        @small -= 1
      else
        @parking_spots[:medium_spot] << movable
        @medium -= 1
      end
      @parking_spots[:large_spot] << car
      return parking_status(car, 'large')
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
      'Car not found'
    end
  end

  def total_occupied
    @parking_spots.values.map(&:size).sum
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    str = plate.to_s.strip
    str.empty? ? nil : str
  end

  def normalize_size(size)
    return nil if size.nil?

    str = size.to_s.strip.downcase
    VALID_SIZES.include?(str) ? str : nil
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.nil? ? nil : license_plate.to_s
    @car_size      = car_size.nil? ? nil : car_size.to_s.strip.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
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
    size = car_size.nil? ? nil : car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours <= GRACE_PERIOD

    hours = duration_hours.ceil
    hours = 1 if hours < 1
    total = hours * RATES[size]
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
      key    = plate.to_s.strip
      ticket = ParkingTicket.new(key, size.to_s.strip.downcase)
      @active_tickets[key] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    key    = plate.nil? ? nil : plate.to_s.strip
    ticket = key && @active_tickets[key]
    return { success: false, message: 'Car not found' } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(key)

    @active_tickets.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @garage.total_occupied,
      total_available:  @garage.small + @garage.medium + @garage.large,
      active_tickets:   @active_tickets.size
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?

    @active_tickets[plate.to_s.strip]
  end

  def active_tickets
    @active_tickets
  end
end