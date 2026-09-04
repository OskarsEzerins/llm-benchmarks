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
    return 'Invalid license plate' if plate.nil?

    size = normalize_size(car_size)
    return 'Invalid car size' if size.nil?

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
      exit_status(plate, false)
    end
  end

  def find_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return nil if plate.nil?

    @parking_spots.each do |spot, cars|
      car = cars.find { |c| c[:plate] == plate }
      return { car: car, spot: spot.to_s.sub('_spot', '') } if car
    end
    nil
  end

  def total_available
    @small + @medium + @large
  end

  def total_occupied
    @parking_spots.values.sum(&:size)
  end

  private

  def normalize_plate(license_plate_no)
    return nil if license_plate_no.nil?
    plate = license_plate_no.to_s.strip
    plate.empty? ? nil : plate
  end

  def normalize_size(car_size)
    return nil if car_size.nil?
    size = car_size.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  end

  # A medium car arrives with no medium or large spots free.
  # Move a small car out of a medium/large spot into a free small spot.
  def shuffle_medium(kar)
    return parking_status unless @small > 0

    victim = @parking_spots[:medium_spot].find { |c| c[:size] == 'small' }
    where  = :medium_spot
    unless victim
      victim = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
      where  = :large_spot
    end
    return parking_status unless victim

    @parking_spots[where].delete(victim)
    @parking_spots[:small_spot] << victim
    @small -= 1
    @parking_spots[where] << kar
    parking_status(kar, where.to_s.sub('_spot', ''))
  end

  # A large car arrives with no large spots free.
  # Move a medium car (to a medium spot) or a small car (to a small/medium spot)
  # out of a large spot.
  def shuffle_large(kar)
    medium_victim = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if medium_victim && @medium > 0
      @parking_spots[:large_spot].delete(medium_victim)
      @parking_spots[:medium_spot] << medium_victim
      @medium -= 1
      @parking_spots[:large_spot] << kar
      return parking_status(kar, 'large')
    end

    small_victim = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
    if small_victim
      if @small > 0
        @parking_spots[:large_spot].delete(small_victim)
        @parking_spots[:small_spot] << small_victim
        @small -= 1
        @parking_spots[:large_spot] << kar
        return parking_status(kar, 'large')
      elsif @medium > 0
        @parking_spots[:large_spot].delete(small_victim)
        @parking_spots[:medium_spot] << small_victim
        @medium -= 1
        @parking_spots[:large_spot] << kar
        return parking_status(kar, 'large')
      end
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

  def exit_status(plate = nil, found = true)
    if plate && found
      "car with license plate no. #{plate} exited"
    elsif plate
      "No car found with license plate no. #{plate}"
    else
      'Invalid license plate'
    end
  end
end

class ParkingTicket
  VALID_SIZES = %w[small medium large].freeze

  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s.strip
    @car_size      = normalize_size(car_size)
    @entry_time    = entry_time || Time.now
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def normalize_size(car_size)
    size = car_size.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  end

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
    return 0.0 if duration_hours.respond_to?(:nan?) && duration_hours.nan?
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
    verdict = @garage.admit_car(plate, size)

    if verdict.to_s.include?('is parked at')
      key    = plate.to_s.strip
      ticket = ParkingTicket.new(key, size)
      @active_tickets[key] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    key    = plate.to_s.strip
    ticket = @active_tickets[key]
    unless ticket
      return { success: false, message: "No active ticket found for license plate no. #{key}" }
    end

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
      total_available:  @garage.total_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end

  def active_tickets
    @active_tickets.values
  end

  def active_ticket_count
    @active_tickets.size
  end

  private

  attr_reader :garage
end