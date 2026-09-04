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

    return 'Invalid license plate' if plate.nil?
    return 'Invalid car size' if size.nil?
    return "car with license plate no. #{plate} is already parked" if find_car(plate)

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
    return exit_status unless plate

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

  def find_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return nil unless plate
    @parking_spots.values.flatten.find { |c| c[:plate] == plate }
  end

  private

  # Medium car needs a medium or large spot; try to relocate a small car
  # occupying one of those spots into a free small spot.
  def shuffle_medium(kar)
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

  # Large car needs a large spot; try to relocate a smaller car occupying
  # a large spot into a free spot that fits it.
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

  def exit_status(plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      'No car found'
    end
  end

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
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.strip.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    (Time.now - entry_time) / 3600.0
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
    rate = RATES[size]
    return 0.0 unless rate
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours.respond_to?(:nan?) && duration_hours.nan?
    return 0.0 if duration_hours <= GRACE_PERIOD_HOURS

    hours = duration_hours.ceil
    total = hours * rate
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
    key    = plate.nil? ? nil : plate.to_s.strip
    ticket = key && @active_tickets[key]
    return { success: false, message: 'No active ticket found' } unless ticket

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
      total_occupied:   @active_tickets.size,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?
    @active_tickets[plate.to_s.strip]
  end

  def active_tickets
    @active_tickets.values
  end
end