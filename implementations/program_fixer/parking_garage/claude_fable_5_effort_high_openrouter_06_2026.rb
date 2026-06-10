require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  VALID_SIZES = %w[small medium large].freeze

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

    return 'No space available' if plate.nil? || size.nil?

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
    plate = license_plate_no.to_s

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

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    str = plate.to_s.strip
    str.empty? ? nil : str
  end

  def normalize_size(size)
    return nil if size.nil?

    normalized = size.to_s.strip.downcase
    VALID_SIZES.include?(normalized) ? normalized : nil
  end

  def shuffle_medium(kar)
    # Try to free up a medium spot by moving a small car to a small spot
    if @small > 0
      small_in_medium = @parking_spots[:medium_spot].find { |c| c[:size] == 'small' }
      if small_in_medium
        @parking_spots[:medium_spot].delete(small_in_medium)
        @parking_spots[:small_spot] << small_in_medium
        @small -= 1
        @parking_spots[:medium_spot] << kar
        return parking_status(kar, 'medium')
      end

      small_in_large = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
      if small_in_large
        @parking_spots[:large_spot].delete(small_in_large)
        @parking_spots[:small_spot] << small_in_large
        @small -= 1
        @parking_spots[:large_spot] << kar
        return parking_status(kar, 'large')
      end
    end

    parking_status
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large_spot].delete(first_medium)
      @parking_spots[:medium_spot] << first_medium
      @medium -= 1
      @parking_spots[:large_spot] << kar
      return parking_status(kar, 'large')
    end

    first_small = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
    if first_small && @small > 0
      @parking_spots[:large_spot].delete(first_small)
      @parking_spots[:small_spot] << first_small
      @small -= 1
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
    if plate
      "car with license plate no. #{plate} exited"
    else
      'No car found'
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
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

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours <= 0
    return 0.0 if duration_hours <= GRACE_PERIOD_HOURS

    hours = duration_hours.ceil
    total = hours * RATES[size]
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
      { success: false, message: result.to_s }
    end
  end

  def exit_car(plate)
    plate_key = plate.to_s.strip
    ticket = @active_tickets[plate_key]
    return { success: false, message: 'No active ticket found' } unless ticket

    fee    = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_key)

    @active_tickets.delete(plate_key)
    {
      success: true,
      message: result,
      fee: fee,
      duration_hours: ticket.duration_hours
    }
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
    @active_tickets.fetch(plate.to_s.strip, nil)
  end
end