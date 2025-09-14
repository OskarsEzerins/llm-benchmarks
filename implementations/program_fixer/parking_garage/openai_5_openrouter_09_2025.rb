require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large, :total_small, :total_medium, :total_large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @total_small  = @small
    @total_medium = @medium
    @total_large  = @large

    @parking_spots = {
      small:  [], # cars parked in small spots
      medium: [], # cars parked in medium spots
      large:  []  # cars parked in large spots
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)
    return "No space available" if plate.nil? || size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      return park_in_available_order(car, [:small, :medium, :large])
    when 'medium'
      return park_in_available_order(car, [:medium, :large])
    when 'large'
      return admit_large_with_shuffle(car)
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    spot_key = nil
    found = nil

    [:small, :medium, :large].each do |key|
      found = @parking_spots[key].find { |c| c[:plate] == plate }
      if found
        spot_key = key
        @parking_spots[key].delete(found)
        case spot_key
        when :small  then @small  += 1
        when :medium then @medium += 1
        when :large  then @large  += 1
        end
        break
      end
    end

    "car with license plate no. #{plate} exited"
  end

  private

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    return nil unless %w[small medium large].include?(s)
    s
  end

  def normalize_plate(plate)
    return nil if plate.nil?
    p = plate.to_s.strip
    return nil if p.empty?
    p
  end

  def park_in_available_order(car, order)
    order.each do |spot|
      case spot
      when :small
        if @small > 0
          @parking_spots[:small] << car
          @small -= 1
          return "car with license plate no. #{car[:plate]} is parked at small"
        end
      when :medium
        if @medium > 0
          @parking_spots[:medium] << car
          @medium -= 1
          return "car with license plate no. #{car[:plate]} is parked at medium"
        end
      when :large
        if @large > 0
          @parking_spots[:large] << car
          @large -= 1
          return "car with license plate no. #{car[:plate]} is parked at large"
        end
      end
    end
    "No space available"
  end

  def admit_large_with_shuffle(car)
    # Try direct large spot first
    if @large > 0
      @parking_spots[:large] << car
      @large -= 1
      return "car with license plate no. #{car[:plate]} is parked at large"
    end

    # Try moving a medium car from large to medium (preferred)
    if @medium > 0
      medium_on_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      if medium_on_large
        @parking_spots[:large].delete(medium_on_large)
        @parking_spots[:medium] << medium_on_large
        @large += 1
        @medium -= 1
        # Now park the large car
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{car[:plate]} is parked at large"
      end
    end

    # Try moving a small car from large to small (preferred) or medium
    small_on_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if small_on_large
      if @small > 0
        @parking_spots[:large].delete(small_on_large)
        @parking_spots[:small] << small_on_large
        @large += 1
        @small -= 1
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{car[:plate]} is parked at large"
      elsif @medium > 0
        @parking_spots[:large].delete(small_on_large)
        @parking_spots[:medium] << small_on_large
        @large += 1
        @medium -= 1
        @parking_spots[:large] << car
        @large -= 1
        return "car with license plate no. #{car[:plate]} is parked at large"
      end
    end

    "No space available"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = normalize_size(car_size) || car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    seconds = Time.now - @entry_time
    return 0.0 if seconds.nil? || seconds < 0
    (seconds / 3600.0).to_f
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    %w[small medium large].include?(s) ? s : nil
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
    size = normalize_size(car_size)
    hours = safe_hours(duration_hours)
    return 0.0 if size.nil? || hours <= 0.0

    return 0.0 if hours <= GRACE_HOURS

    billable = (hours - GRACE_HOURS)
    billable_hours = billable.ceil
    rate = RATES[size]
    total = (billable_hours * rate).to_f
    [total, MAX_FEE[size]].min.to_f
  rescue
    0.0
  end

  private

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    %w[small medium large].include?(s) ? s : nil
  end

  def safe_hours(h)
    return 0.0 if h.nil?
    f = h.to_f
    f.negative? ? 0.0 : f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @active_tickets  = {}
  end

  def admit_car(plate, size)
    plate_s = normalize_plate(plate)
    msg = @garage.admit_car(plate_s, size)
    if msg.to_s.include?('parked')
      ticket = ParkingTicket.new(plate_s, size)
      @active_tickets[plate_s] = ticket
      { success: true, message: msg, ticket: ticket }
    else
      { success: false, message: msg }
    end
  end

  def exit_car(plate)
    plate_s = normalize_plate(plate)
    ticket = @active_tickets[plate_s]
    return { success: false, message: 'No active ticket' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    msg = @garage.exit_car(plate_s)
    @active_tickets.delete(plate_s)

    { success: true, message: msg, fee: fee.to_f, duration_hours: duration.to_f }
  end

  def garage_status
    small_avail  = @garage.small
    med_avail    = @garage.medium
    large_avail  = @garage.large

    total_cap = @garage.total_small + @garage.total_medium + @garage.total_large
    total_avail = small_avail + med_avail + large_avail
    total_occupied = total_cap - total_avail

    {
      small_available: small_avail,
      medium_available: med_avail,
      large_available: large_avail,
      total_occupied: total_occupied,
      total_available: total_avail
    }
  end

  def find_ticket(plate)
    @active_tickets[normalize_plate(plate)]
  end

  private

  def normalize_plate(plate)
    return '' if plate.nil?
    plate.to_s.strip
  end
end