require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  VALID_SIZES = %w[small medium large].freeze

  def initialize(small, medium, large)
    @small = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large = [large.to_i, 0].max

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)
    return 'No space available' if plate.nil? || size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small.positive?
        park_in(:small, car)
      elsif @medium.positive?
        park_in(:medium, car)
      elsif @large.positive?
        park_in(:large, car)
      else
        'No space available'
      end
    when 'medium'
      if @medium.positive?
        park_in(:medium, car)
      elsif @large.positive?
        park_in(:large, car)
      else
        'No space available'
      end
    when 'large'
      if @large.positive?
        park_in(:large, car)
      elsif shuffle_for_large
        park_in(:large, car)
      else
        'No space available'
      end
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Car not found' if plate.nil?

    [:small, :medium, :large].each do |spot_type|
      idx = @parking_spots[spot_type].find_index { |c| c[:plate] == plate }
      next unless idx

      @parking_spots[spot_type].delete_at(idx)
      increment_available(spot_type)
      return "car with license plate no. #{plate} exited"
    end

    'Car not found'
  end

  def occupied_count
    @parking_spots.values.map(&:size).sum
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?
    value = plate.to_s.strip
    return nil if value.empty?

    value
  end

  def normalize_size(size)
    return nil if size.nil?
    normalized = size.to_s.strip.downcase
    VALID_SIZES.include?(normalized) ? normalized : nil
  end

  def park_in(spot_type, car)
    @parking_spots[spot_type] << car
    decrement_available(spot_type)
    "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
  end

  def decrement_available(spot_type)
    case spot_type
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
  end

  def increment_available(spot_type)
    case spot_type
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end
  end

  def move_car(from_type, to_type, index)
    car = @parking_spots[from_type].delete_at(index)
    return false unless car

    @parking_spots[to_type] << car
    increment_available(from_type)
    decrement_available(to_type)
    true
  end

  def shuffle_for_large
    return false if @large.positive?

    # 1) Move medium from large -> medium if possible
    if @medium.positive?
      idx = @parking_spots[:large].find_index { |c| c[:size] == 'medium' }
      return true if idx && move_car(:large, :medium, idx)
    end

    # 2) Move small from large -> small/medium if possible
    idx_small_in_large = @parking_spots[:large].find_index { |c| c[:size] == 'small' }
    if idx_small_in_large
      if @small.positive?
        return true if move_car(:large, :small, idx_small_in_large)
      elsif @medium.positive?
        return true if move_car(:large, :medium, idx_small_in_large)
      end
    end

    # 3) Cascade: small from medium -> small, then medium from large -> medium
    if @small.positive?
      idx_small_in_medium = @parking_spots[:medium].find_index { |c| c[:size] == 'small' }
      idx_medium_in_large = @parking_spots[:large].find_index { |c| c[:size] == 'medium' }

      if idx_small_in_medium && idx_medium_in_large
        moved1 = move_car(:medium, :small, idx_small_in_medium)
        moved2 = move_car(:large, :medium, idx_medium_in_large)
        return true if moved1 && moved2
      end
    end

    false
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).to_f
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

  GRACE_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    rate = RATES[size]
    max = MAX_FEE[size]
    return 0.0 if rate.nil? || max.nil?

    duration = begin
      Float(duration_hours)
    rescue StandardError
      nil
    end
    return 0.0 if duration.nil? || duration.negative?
    return 0.0 if duration <= GRACE_HOURS

    hours = duration.ceil
    fee = hours * rate
    [fee, max].min.to_f
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **kwargs)
    if kwargs.any?
      small_spots = kwargs[:small_spots]
      medium_spots = kwargs[:medium_spots]
      large_spots = kwargs[:large_spots]
    end

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(license_plate, car_size)
    plate = normalize_plate(license_plate)
    size = normalize_size(car_size)

    return { success: false, message: 'Invalid license plate' } if plate.nil?
    return { success: false, message: 'Invalid car size' } if size.nil?
    return { success: false, message: 'Car already parked' } if @active_tickets.key?(plate)

    message = @garage.admit_car(plate, size)

    if message.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(license_plate)
    plate = normalize_plate(license_plate)
    return { success: false, message: 'Invalid license plate' } if plate.nil?

    ticket = @active_tickets[plate]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(plate)

    if message.include?('exited')
      @active_tickets.delete(plate)
      { success: true, message: message, fee: fee, duration_hours: duration }
    else
      { success: false, message: message, fee: fee, duration_hours: duration }
    end
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large
    total_occupied = @garage.occupied_count

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(license_plate)
    plate = normalize_plate(license_plate)
    return nil if plate.nil?

    @active_tickets[plate]
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?
    value = plate.to_s.strip
    return nil if value.empty?

    value
  end

  def normalize_size(size)
    normalized = size.to_s.strip.downcase
    %w[small medium large].include?(normalized) ? normalized : nil
  end
end