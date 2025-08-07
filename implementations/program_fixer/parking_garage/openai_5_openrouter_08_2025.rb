require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small:  [],  # cars stored as { plate: 'ABC123', size: 'small'|'medium'|'large' }
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)

    return "No space available" if plate.empty?
    return "No space available" unless %w[small medium large].include?(size)
    return "car with license plate no. #{plate} is already parked" if parked?(plate)

    case size
    when 'small'
      return park_in(:small, plate, size)  if @small > 0
      return park_in(:medium, plate, size) if @medium > 0
      return park_in(:large, plate, size)  if @large > 0
      "No space available"
    when 'medium'
      return park_in(:medium, plate, size) if @medium > 0
      return park_in(:large, plate, size)  if @large > 0
      "No space available"
    when 'large'
      return park_in(:large, plate, size) if @large > 0

      # Try shuffling: move a medium/small currently in large to smaller appropriate spot to free a large spot
      if try_shuffle_to_free_large
        return park_in(:large, plate, size)
      end

      "No space available"
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    [:small, :medium, :large].each do |spot|
      car = @parking_spots[spot].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot].delete(car)
      case spot
      when :small  then @small  += 1
      when :medium then @medium += 1
      when :large  then @large  += 1
      end
      return "car with license plate no. #{plate} exited"
    end
    "No car found"
  end

  private

  def normalize_plate(plate)
    (plate.nil? ? "" : plate.to_s).strip
  end

  def normalize_size(size)
    (size.nil? ? "" : size.to_s.downcase.strip)
  end

  def parked?(plate)
    @parking_spots.values.flatten.any? { |c| c[:plate] == plate }
  end

  def park_in(spot_type, plate, size)
    @parking_spots[spot_type] << { plate: plate, size: size }
    case spot_type
    when :small  then @small  -= 1
    when :medium then @medium -= 1
    when :large  then @large  -= 1
    end
    "car with license plate no. #{plate} is parked at #{spot_type.to_s}"
  end

  def try_shuffle_to_free_large
    # Strategy:
    # 1) Move a medium car from large -> medium if available
    # 2) Else move a small car from large -> small if available
    # 3) Else move a small car from large -> medium if available
    # 4) Else move a medium from large -> large not possible, or small from large -> small/medium not available
    # If any move succeeds, return true
    # Try medium from large to medium
    if @medium > 0
      victim = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      if victim
        @parking_spots[:large].delete(victim)
        @large += 1
        @parking_spots[:medium] << victim
        @medium -= 1
        return true
      end
    end

    # Move small from large to small
    if @small > 0
      victim = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if victim
        @parking_spots[:large].delete(victim)
        @large += 1
        @parking_spots[:small] << victim
        @small -= 1
        return true
      end
    end

    # Move small from large to medium if small not available but medium is
    if @medium > 0
      victim = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if victim
        @parking_spots[:large].delete(victim)
        @large += 1
        @parking_spots[:medium] << victim
        @medium -= 1
        return true
      end
    end

    false
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = (license_plate.nil? ? "" : license_plate.to_s).strip
    @car_size      = (car_size.nil? ? "" : car_size.to_s.downcase.strip)
    @entry_time    = entry_time
  end

  def duration_hours
    seconds = Time.now - @entry_time
    return 0.0 if seconds.nil? || seconds.nan? || seconds.infinite? || seconds < 0
    (seconds / 3600.0).to_f
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

  GRACE_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = (car_size.nil? ? "" : car_size.to_s.downcase.strip)
    dur  = duration_hours.is_a?(Numeric) ? duration_hours.to_f : nil
    return 0.0 unless dur && dur.finite? && dur >= 0.0
    rate = RATES[size]
    return 0.0 unless rate

    return 0.0 if dur <= GRACE_HOURS

    billable_hours = (dur - GRACE_HOURS)
    hours_to_bill  = billable_hours.ceil
    total          = (hours_to_bill * rate).to_f
    max_cap        = MAX_FEE[size] || Float::INFINITY
    [total, max_cap].min.to_f
  end
end

class ParkingGarageManager
  def initialize(*args, **kwargs)
    if args.size == 3
      small_spots, medium_spots, large_spots = args
    elsif kwargs.any?
      small_spots  = kwargs[:small_spots]  || kwargs[:small]  || 0
      medium_spots = kwargs[:medium_spots] || kwargs[:medium] || 0
      large_spots  = kwargs[:large_spots]  || kwargs[:large]  || 0
    else
      small_spots = medium_spots = large_spots = 0
    end

    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @active_tickets  = {}
  end

  def admit_car(license_plate, car_size)
    plate = normalize_plate(license_plate)
    size  = normalize_size(car_size)

    return { success: false, message: 'Invalid license plate' } if plate.empty?
    return { success: false, message: 'Invalid car size' } unless %w[small medium large].include?(size)

    result = @garage.admit_car(plate, size)
    if result.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(license_plate)
    plate = normalize_plate(license_plate)
    ticket = @active_tickets[plate]
    return { success: false, message: 'No active ticket' } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message  = @garage.exit_car(plate)

    @active_tickets.delete(plate)

    { success: true, message: message, fee: fee.to_f, duration_hours: duration.to_f }
  end

  def garage_status
    small_available  = @garage.small
    medium_available = @garage.medium
    large_available  = @garage.large
    total_available  = small_available + medium_available + large_available

    total_occupied = @active_tickets.size

    {
      small_available:  small_available,
      medium_available: medium_available,
      large_available:  large_available,
      total_occupied:   total_occupied,
      total_available:  total_available
    }
  end

  def find_ticket(license_plate)
    @active_tickets[normalize_plate(license_plate)]
  end

  private

  def normalize_plate(plate)
    (plate.nil? ? "" : plate.to_s).strip
  end

  def normalize_size(size)
    (size.nil? ? "" : size.to_s.downcase.strip)
  end
end