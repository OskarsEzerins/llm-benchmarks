require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots

  def initialize(small, medium, large)
    @small_capacity  = [small.to_i, 0].max
    @medium_capacity = [medium.to_i, 0].max
    @large_capacity  = [large.to_i, 0].max
    @parking_spots   = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)

    return 'Invalid license plate' if plate.empty?
    return 'Invalid car size' unless size
    return "car with license plate no. #{plate} is already parked" if car_present?(plate)

    case size
    when 'small'
      attempt_small(plate, size)
    when 'medium'
      attempt_medium(plate, size)
    when 'large'
      attempt_large(plate, size)
    else
      'Invalid car size'
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Invalid license plate' if plate.empty?

    car_data = find_car(plate)

    if car_data
      car, spot_type = car_data
      @parking_spots[spot_type].delete(car)
      "car with license plate no. #{plate} exited"
    else
      "No car found with license plate no. #{plate}"
    end
  end

  def small_available
    [capacity_for(:small) - @parking_spots[:small].size, 0].max
  end

  def medium_available
    [capacity_for(:medium) - @parking_spots[:medium].size, 0].max
  end

  def large_available
    [capacity_for(:large) - @parking_spots[:large].size, 0].max
  end

  def total_capacity
    @small_capacity + @medium_capacity + @large_capacity
  end

  def total_occupied
    @parking_spots.values.sum(&:size)
  end

  def total_available
    total_capacity - total_occupied
  end

  private

  def attempt_small(plate, size)
    return park_car(plate, size, :small)  if small_available.positive?
    return park_car(plate, size, :medium) if medium_available.positive?
    return park_car(plate, size, :large)  if ensure_large_spot

    'No space available'
  end

  def attempt_medium(plate, size)
    if medium_available.positive? || ensure_medium_spot
      return park_car(plate, size, :medium)
    end
    return park_car(plate, size, :large) if ensure_large_spot

    'No space available'
  end

  def attempt_large(plate, size)
    return park_car(plate, size, :large) if ensure_large_spot

    'No space available'
  end

  def park_car(plate, size, spot_type)
    car = { plate: plate, size: size, spot_type: spot_type }
    @parking_spots[spot_type] << car
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def ensure_medium_spot
    return true if medium_available.positive?

    car = @parking_spots[:medium].find { |c| c[:size] == 'small' }
    if car && small_available.positive?
      move_car(car, :medium, :small)
      return true
    end
    false
  end

  def ensure_large_spot
    return true if large_available.positive?

    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if medium_in_large && ensure_medium_spot
      move_car(medium_in_large, :large, :medium)
      return true
    end

    small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if small_in_large
      if small_available.positive?
        move_car(small_in_large, :large, :small)
        return true
      elsif ensure_medium_spot
        move_car(small_in_large, :large, :medium)
        return true
      end
    end
    large_available.positive?
  end

  def move_car(car, from, to)
    @parking_spots[from].delete(car)
    car[:spot_type] = to
    @parking_spots[to] << car
  end

  def capacity_for(type)
    case type
    when :small  then @small_capacity
    when :medium then @medium_capacity
    when :large  then @large_capacity
    else 0
    end
  end

  def car_present?(plate)
    @parking_spots.values.any? { |cars| cars.any? { |c| c[:plate] == plate } }
  end

  def find_car(plate)
    @parking_spots.each do |type, cars|
      car = cars.find { |c| c[:plate] == plate }
      return [car, type] if car
    end
    nil
  end

  def normalize_plate(plate)
    plate.to_s.strip
  end

  def normalize_size(car_size)
    return nil if car_size.nil?
    normalized = car_size.to_s.strip.downcase
    return normalized if %w[small medium large].include?(normalized)
    nil
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size      = car_size.to_s.strip.downcase
    @entry_time    = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
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

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil?

    size = normalize_size(car_size)
    hours = duration_hours.to_f
    return 0.0 if size.nil? || hours <= GRACE_PERIOD_HOURS

    rate = RATES[size]
    billable_hours = (hours - GRACE_PERIOD_HOURS)
    total_hours = billable_hours.ceil
    total = total_hours * rate
    [total, MAX_FEE[size]].min
  end

  private

  def normalize_size(car_size)
    return nil if car_size.nil?
    size = car_size.to_s.strip.downcase
    RATES.key?(size) ? size : nil
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @active_tickets  = {}
  end

  def admit_car(license_plate, car_size)
    plate_key = normalize_plate(license_plate)
    size_key  = normalize_size(car_size)

    response = @garage.admit_car(plate_key, size_key || car_size)

    if response.include?('is parked at')
      ticket = ParkingTicket.new(plate_key, size_key)
      @active_tickets[plate_key] = ticket
      {
        success: true,
        message: response,
        ticket:  ticket
      }
    else
      { success: false, message: response }
    end
  end

  def exit_car(license_plate)
    plate_key = normalize_plate(license_plate)
    ticket = @active_tickets[plate_key]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    garage_message = @garage.exit_car(plate_key)

    success = garage_message.include?('exited')

    if success
      @active_tickets.delete(plate_key)
      {
        success:        true,
        message:        garage_message,
        fee:            fee,
        duration_hours: duration.round(2),
        ticket_valid:   ticket.valid?
      }
    else
      { success: false, message: garage_message }
    end
  end

  def garage_status
    {
      small_available:  @garage.small_available,
      medium_available: @garage.medium_available,
      large_available:  @garage.large_available,
      total_occupied:   @garage.total_occupied,
      total_available:  @garage.total_available,
      active_tickets:   @active_tickets.size
    }
  end

  def find_ticket(license_plate)
    plate_key = normalize_plate(license_plate)
    @active_tickets[plate_key]
  end

  private

  def normalize_plate(plate)
    plate.to_s.strip
  end

  def normalize_size(size)
    return nil if size.nil?
    normalized = size.to_s.strip.downcase
    %w[small medium large].include?(normalized) ? normalized : nil
  end
end