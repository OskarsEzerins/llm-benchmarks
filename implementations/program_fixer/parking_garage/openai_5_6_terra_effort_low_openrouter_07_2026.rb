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

    return 'No space available' unless plate && size
    return 'No space available' if parked?(plate)

    spot = find_available_spot(size)

    unless spot
      case size
      when 'medium'
        free_medium_spot
      when 'large'
        free_large_spot
      end

      spot = find_available_spot(size)
    end

    return 'No space available' unless spot

    car = { plate: plate, size: size }
    park_car(car, spot)

    parking_status(car, spot.to_s)
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status unless plate

    [:small, :medium, :large].each do |spot|
      car = @parking_spots[spot].find { |vehicle| vehicle[:plate] == plate }

      next unless car

      @parking_spots[spot].delete(car)
      increase_availability(spot)
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    return parking_status unless free_medium_spot

    spot = find_available_spot(car[:size])
    return parking_status unless spot

    park_car(car, spot)
    parking_status(car, spot.to_s)
  end

  def shuffle_large(car)
    return parking_status unless free_large_spot

    park_car(car, :large)
    parking_status(car, 'large')
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    return 'No car found' unless plate

    "car with license plate no. #{plate} exited"
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    value = plate.to_s.strip
    value.empty? ? nil : value
  end

  def normalize_size(size)
    return nil if size.nil?

    value = size.to_s.strip.downcase
    VALID_SIZES.include?(value) ? value : nil
  end

  def parked?(plate)
    @parking_spots.values.flatten.any? { |car| car[:plate] == plate }
  end

  def find_available_spot(size)
    case size
    when 'small'
      return :small if @small.positive?
      return :medium if @medium.positive?
      return :large if @large.positive?
    when 'medium'
      return :medium if @medium.positive?
      return :large if @large.positive?
    when 'large'
      return :large if @large.positive?
    end

    nil
  end

  def park_car(car, spot)
    @parking_spots[spot] << car
    decrease_availability(spot)
  end

  def move_car(car, from, to)
    @parking_spots[from].delete(car)
    increase_availability(from)
    @parking_spots[to] << car
    decrease_availability(to)
  end

  def free_medium_spot
    return true if @medium.positive?
    return false unless @small.positive?

    small_car = @parking_spots[:medium].find { |car| car[:size] == 'small' }
    return false unless small_car

    move_car(small_car, :medium, :small)
    true
  end

  def free_large_spot
    return true if @large.positive?

    @parking_spots[:large].dup.each do |car|
      if car[:size] == 'medium'
        if free_medium_spot
          move_car(car, :large, :medium)
          return true
        end
      elsif car[:size] == 'small'
        if @small.positive?
          move_car(car, :large, :small)
          return true
        end

        if free_medium_spot
          move_car(car, :large, :medium)
          return true
        end
      end
    end

    false
  end

  def decrease_availability(spot)
    case spot
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
  end

  def increase_availability(spot)
    case spot
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [((Time.now - @entry_time) / 3600.0), 0.0].max
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.hex(8).upcase}"
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

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = normalize_size(car_size)
    duration = normalize_duration(duration_hours)

    return 0.0 unless size && duration
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    hours = duration.ceil
    fee = hours * RATES[size]

    [fee, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_size(size)
    value = size.to_s.strip.downcase
    RATES.key?(value) ? value : nil
  end

  def normalize_duration(duration)
    value = Float(duration)
    value.negative? || !value.finite? ? nil : value
  rescue ArgumentError, TypeError
    nil
  end
end

class ParkingGarageManager
  def initialize(*args, small_spots: nil, medium_spots: nil, large_spots: nil)
    if args.any?
      small_spots, medium_spots, large_spots = args
    end

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    unless normalized_plate && normalized_size
      return { success: false, message: 'No space available' }
    end

    if @tix_in_flight.key?(normalized_plate)
      return { success: false, message: 'No space available' }
    end

    result = @garage.admit_car(normalized_plate, normalized_size)

    unless result.include?('is parked at')
      return { success: false, message: result }
    end

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @tix_in_flight[normalized_plate] = ticket

    {
      success: true,
      message: result,
      ticket: ticket
    }
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    ticket = normalized_plate && @tix_in_flight[normalized_plate]

    unless ticket
      return { success: false, message: 'No active ticket found' }
    end

    unless ticket.valid?
      return { success: false, message: 'Ticket has expired' }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(normalized_plate)

    unless result.include?('exited')
      return { success: false, message: result }
    end

    @tix_in_flight.delete(normalized_plate)

    {
      success: true,
      message: result,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.parking_spots.values.sum(&:size),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    normalized_plate = normalize_plate(plate)
    normalized_plate ? @tix_in_flight[normalized_plate] : nil
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?

    value = plate.to_s.strip
    value.empty? ? nil : value
  end

  def normalize_size(size)
    return nil if size.nil?

    value = size.to_s.strip.downcase
    ParkingGarage::VALID_SIZES.include?(value) ? value : nil
  end
end