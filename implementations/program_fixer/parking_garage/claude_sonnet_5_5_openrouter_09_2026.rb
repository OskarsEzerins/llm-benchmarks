require 'securerandom'

class ParkingGarage
  SIZES = %w[small medium large].freeze

  attr_reader :parking_spots

  def initialize(small, medium, large)
    @capacity = {
      'small'  => [small.to_i, 0].max,
      'medium' => [medium.to_i, 0].max,
      'large'  => [large.to_i, 0].max
    }
    @available = @capacity.dup

    @parking_spots = {
      small_spot:  [],
      medium_spot: [],
      large_spot:  []
    }
  end

  def small
    @available['small']
  end

  def medium
    @available['medium']
  end

  def large
    @available['large']
  end

  def total_capacity
    @capacity.values.sum
  end

  def total_occupied
    @parking_spots.values.map(&:size).sum
  end

  def total_available
    @available.values.sum
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
      if small > 0
        place(kar, 'small')
      elsif medium > 0
        place(kar, 'medium')
      elsif large > 0
        place(kar, 'large')
      else
        parking_status
      end
    when 'medium'
      if medium > 0
        place(kar, 'medium')
      elsif large > 0
        place(kar, 'large')
      else
        shuffle_medium(kar)
      end
    when 'large'
      if large > 0
        place(kar, 'large')
      else
        shuffle_large(kar)
      end
    else
      parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status if plate.nil?

    found = find_car(plate)
    return exit_status(plate, false) unless found

    car, type = found
    remove(car, type)
    exit_status(plate)
  end

  def shuffle_medium(kar)
    # Try to move a small car sitting in a medium/large spot into a free small spot
    if small > 0
      %w[medium large].each do |type|
        victim = @parking_spots[spot_key(type)].find { |c| c[:size] == 'small' }
        next unless victim

        remove(victim, type)
        place(victim, 'small')
        return place(kar, type)
      end
    end
    parking_status
  end

  def shuffle_large(kar)
    victim = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if victim && medium > 0
      remove(victim, 'large')
      place(victim, 'medium')
      return place(kar, 'large')
    end

    victim = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
    if victim
      target = if small > 0
                 'small'
               elsif medium > 0
                 'medium'
               end
      if target
        remove(victim, 'large')
        place(victim, target)
        return place(kar, 'large')
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
    if plate.nil?
      'Invalid license plate'
    elsif found
      "car with license plate no. #{plate} exited"
    else
      "car with license plate no. #{plate} not found"
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

    str = size.to_s.strip.downcase
    SIZES.include?(str) ? str : nil
  end

  def spot_key(type)
    "#{type}_spot".to_sym
  end

  def place(kar, type)
    @parking_spots[spot_key(type)] << kar
    @available[type] -= 1
    parking_status(kar, type)
  end

  def remove(kar, type)
    @parking_spots[spot_key(type)].delete(kar)
    @available[type] += 1
  end

  def find_car(plate)
    SIZES.each do |type|
      car = @parking_spots[spot_key(type)].find { |c| c[:plate] == plate }
      return [car, type] if car
    end
    nil
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.strip.downcase
    @entry_time    = entry_time || Time.now
  end

  def duration_hours
    (Time.now - entry_time) / 3600.0
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
    return 0.0 if car_size.nil?

    size = car_size.to_s.strip.downcase
    rate = RATES[size]
    return 0.0 unless rate

    duration = begin
      Float(duration_hours)
    rescue ArgumentError, TypeError
      return 0.0
    end

    return 0.0 if duration.nan? || duration < 0
    return 0.0 if duration <= GRACE_PERIOD

    hours = duration.infinite? ? 24 : duration.ceil
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
    key     = plate.to_s.strip
    message = @garage.admit_car(plate, size)

    if message.include?('is parked at')
      ticket = ParkingTicket.new(key, size)
      @active_tickets[key] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    key    = plate.to_s.strip
    ticket = @active_tickets[key]
    return { success: false, message: "car with license plate no. #{key} not found" } unless ticket

    duration = ticket.duration_hours.round(2)
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration).to_f
    message  = @garage.exit_car(key)

    @active_tickets.delete(key)
    { success: true, message: message, fee: fee, duration_hours: duration }
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
end