require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots

  def initialize(small, medium, large)
    @capacities = {
      small:  [small.to_i, 0].max,
      medium: [medium.to_i, 0].max,
      large:  [large.to_i, 0].max
    }
    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def small
    available_for(:small)
  end

  def medium
    available_for(:medium)
  end

  def large
    available_for(:large)
  end

  def total_capacity
    @capacities.values.inject(0) { |sum, value| sum + value }
  end

  def total_occupied
    @parking_spots.values.inject(0) { |sum, cars| sum + cars.size }
  end

  def total_available
    total_capacity - total_occupied
  end

  def admit_car(license_plate_no, car_size)
    license = normalize_license(license_plate_no)
    return "Invalid license plate number" unless license

    size = normalize_car_size(car_size)
    return "Invalid car size" unless size

    return "car with license plate no. #{license} is already parked" if car_present?(license)

    spot = determine_spot_for(size)
    return "No space available" unless spot

    car = { plate: license, size: size, spot: spot }
    @parking_spots[spot] << car
    "car with license plate no. #{license} is parked at #{spot}"
  end

  def exit_car(license_plate_no)
    license = normalize_license(license_plate_no)
    return "Invalid license plate number" unless license

    car, spot = locate_car(license)
    return "car with license plate no. #{license} not found" unless car

    @parking_spots[spot].delete(car)
    "car with license plate no. #{license} exited"
  end

  def car_details(license_plate_no)
    license = normalize_license(license_plate_no)
    return nil unless license

    car, = locate_car(license)
    car ? car.dup : nil
  end

  private

  def normalize_license(plate)
    return nil if plate.nil?
    normalized = plate.to_s.strip
    return nil if normalized.empty?
    normalized.upcase
  end

  def normalize_car_size(size)
    return nil if size.nil?
    normalized = size.to_s.strip.downcase
    return nil unless %w[small medium large].include?(normalized)
    normalized
  end

  def car_present?(license)
    car, = locate_car(license)
    !car.nil?
  end

  def locate_car(license)
    @parking_spots.each do |spot, cars|
      car = cars.find { |c| c[:plate] == license }
      return [car, spot] if car
    end
    [nil, nil]
  end

  def available_for(type)
    remaining = @capacities[type] - @parking_spots[type].size
    remaining < 0 ? 0 : remaining
  end

  def determine_spot_for(size)
    case size
    when 'small'
      choose_spot(%i[small medium large])
    when 'medium'
      choose_spot(%i[medium large])
    when 'large'
      select_large_spot
    else
      nil
    end
  end

  def choose_spot(order)
    order.find { |spot| available_for(spot) > 0 }
  end

  def select_large_spot
    return :large if available_for(:large) > 0
    return nil if @capacities[:large].zero?

    attempt_large_shuffle
  end

  def attempt_large_shuffle
    if available_for(:medium) > 0
      medium_car = @parking_spots[:large].find { |car| car[:size] == 'medium' }
      if medium_car
        relocate_car(medium_car, :large, :medium)
        return :large if available_for(:large) > 0
      end
    end

    small_car = @parking_spots[:large].find { |car| car[:size] == 'small' }
    if small_car
      if available_for(:small) > 0
        relocate_car(small_car, :large, :small)
        return :large if available_for(:large) > 0
      elsif available_for(:medium) > 0
        relocate_car(small_car, :large, :medium)
        return :large if available_for(:large) > 0
      end
    end

    nil
  end

  def relocate_car(car, from_spot, to_spot)
    return unless car
    return if available_for(to_spot) <= 0

    @parking_spots[from_spot].delete(car)
    car[:spot] = to_spot
    @parking_spots[to_spot] << car
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = sanitize_license(license_plate)
    @car_size = sanitize_car_size(car_size)
    @entry_time =
      if entry_time.is_a?(Time)
        entry_time
      elsif entry_time.respond_to?(:to_time)
        entry_time.to_time
      else
        Time.now
      end
  end

  def duration_hours(reference_time = Time.now)
    ref_time = reference_time.is_a?(Time) ? reference_time : Time.now
    seconds = ref_time.to_f - @entry_time.to_f
    hours = seconds / 3600.0
    hours = 0.0 if hours.negative?
    hours.round(2)
  end

  def valid?(reference_time = Time.now)
    ref_time = reference_time.is_a?(Time) ? reference_time : Time.now
    (ref_time.to_f - @entry_time.to_f) <= 24 * 3600
  end

  private

  def sanitize_license(license_plate)
    return '' if license_plate.nil?
    license_plate.to_s.strip.upcase
  end

  def sanitize_car_size(car_size)
    value = car_size.to_s.strip.downcase
    %w[small medium large].include?(value) ? value : ''
  end

  def generate_ticket_id
    "TK-#{SecureRandom.hex(6)}"
  end
end

class ParkingFeeCalculator
  GRACE_PERIOD = 0.25
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

  def calculate_fee(car_size, duration_hours)
    normalized_size = normalize_car_size(car_size)
    return 0.0 unless normalized_size

    duration = normalize_duration(duration_hours)
    return 0.0 if duration <= GRACE_PERIOD

    billable_hours = (duration - GRACE_PERIOD).ceil
    fee = billable_hours * RATES[normalized_size]
    [fee, MAX_FEE[normalized_size]].min.to_f
  end

  private

  def normalize_car_size(size)
    return nil if size.nil?
    normalized = size.to_s.strip.downcase
    RATES.key?(normalized) ? normalized : nil
  end

  def normalize_duration(duration)
    value = begin
      Float(duration)
    rescue ArgumentError, TypeError
      nil
    end
    return 0.0 if value.nil? || value.nan? || value.negative?
    value = 24.0 if value.infinite?
    value
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    message = @garage.admit_car(plate, size)

    unless message.include?('is parked at')
      return { success: false, message: message }
    end

    license = normalize_plate(plate) || extract_plate_from_message(message)
    return { success: false, message: message } unless license

    ticket_size = normalize_size(size)
    if ticket_size.nil?
      details = @garage.car_details(license)
      ticket_size = details[:size] if details
    end
    return { success: false, message: "Unable to determine car size for ticket" } unless ticket_size

    ticket = ParkingTicket.new(license, ticket_size)
    @tickets[ticket.license_plate] = ticket

    { success: true, message: message, ticket: ticket }
  end

  def exit_car(plate)
    license = normalize_plate(plate)
    return { success: false, message: "Invalid license plate number" } unless license

    ticket = @tickets[license]
    return { success: false, message: "No active ticket found for car with license plate no. #{license}" } unless ticket

    exit_message = @garage.exit_car(license)
    unless exit_message.include?('exited')
      return { success: false, message: exit_message }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    @tickets.delete(license)

    {
      success: true,
      message: exit_message,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.total_occupied,
      total_available: @garage.total_available,
      active_tickets: @tickets.size
    }
  end

  def find_ticket(plate)
    license = normalize_plate(plate)
    return nil unless license
    @tickets[license]
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?
    normalized = plate.to_s.strip
    return nil if normalized.empty?
    normalized.upcase
  end

  def normalize_size(size)
    return nil if size.nil?
    normalized = size.to_s.strip.downcase
    %w[small medium large].include?(normalized) ? normalized : nil
  end

  def extract_plate_from_message(message)
    return nil unless message
    match = message.match(/car with license plate no\. (.+?) (?:is|not|exited)/i)
    match ? match[1].strip.upcase : nil
  end
end