require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  VALID_SIZES = %w[small medium large].freeze

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
        park(kar, :small)
      elsif @medium > 0
        park(kar, :medium)
      elsif @large > 0
        park(kar, :large)
      else
        'No space available'
      end
    when 'medium'
      if @medium > 0
        park(kar, :medium)
      elsif @large > 0
        park(kar, :large)
      else
        'No space available'
      end
    when 'large'
      if @large > 0
        park(kar, :large)
      else
        shuffle_large(kar) || 'No space available'
      end
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'No space available' if plate.nil?

    [:small, :medium, :large].each do |spot_type|
      car = @parking_spots[spot_type].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot_type].delete(car)
      increment(spot_type)
      return "car with license plate no. #{plate} exited"
    end

    "No car found with license plate no. #{plate}"
  end

  private

  def park(kar, spot_type)
    @parking_spots[spot_type] << kar
    decrement(spot_type)
    "car with license plate no. #{kar[:plate]} is parked at #{spot_type}"
  end

  def decrement(spot_type)
    case spot_type
    when :small  then @small  -= 1
    when :medium then @medium -= 1
    when :large  then @large  -= 1
    end
  end

  def increment(spot_type)
    case spot_type
    when :small  then @small  += 1
    when :medium then @medium += 1
    when :large  then @large  += 1
    end
  end

  def shuffle_large(kar)
    candidate = @parking_spots[:large].find { |c| c[:size] != 'large' }
    return nil unless candidate

    target = candidate[:size].to_sym
    return nil unless instance_variable_get("@#{target}") > 0

    @parking_spots[:large].delete(candidate)
    @parking_spots[target] << candidate
    decrement(target)

    @parking_spots[:large] << kar
    "car with license plate no. #{kar[:plate]} is parked at large"
  end

  def normalize_plate(plate)
    return nil if plate.nil?

    str = plate.to_s.strip
    return nil if str.empty?

    str
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
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.strip.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    (Time.now - entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24
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
    return 0.0 if duration_hours < 0
    return 0.0 if duration_hours <= GRACE_PERIOD_HOURS

    billable_hours = duration_hours.ceil
    total          = billable_hours * RATES[size]

    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets        = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)

    if result.to_s.include?('is parked at')
      normalized_plate = plate.to_s.strip
      ticket = ParkingTicket.new(normalized_plate, size)
      @tickets[normalized_plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    normalized_plate = plate.to_s.strip
    ticket = @tickets[normalized_plate]
    return { success: false, message: 'No active ticket found' } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(normalized_plate)

    @tickets.delete(normalized_plate)

    { success: true, message: result, fee: fee, duration_hours: duration.round(2) }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @tickets.size,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s.strip]
  end
end