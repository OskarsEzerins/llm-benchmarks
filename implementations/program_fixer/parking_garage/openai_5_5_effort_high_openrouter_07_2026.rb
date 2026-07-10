require 'securerandom'
require 'time'

class ParkingGarage
  VALID_SIZES = %w[small medium large].freeze
  NO_SPACE_MESSAGE = 'No space available'.freeze

  SPOT_ORDER = {
    'small' => %i[small medium large],
    'medium' => %i[medium large],
    'large' => %i[large]
  }.freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @capacity = {
      small: nonnegative_integer(small),
      medium: nonnegative_integer(medium),
      large: nonnegative_integer(large)
    }

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }

    refresh_available!
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)

    return NO_SPACE_MESSAGE if plate.nil? || size.nil?
    return NO_SPACE_MESSAGE if parked?(plate)

    car = { plate: plate, size: size }
    spot = find_spot_for(size)

    if spot.nil? && size == 'medium'
      compact_for_medium!
      spot = find_spot_for(size)
    elsif spot.nil? && size == 'large'
      compact_for_large!
      spot = find_spot_for(size)
    end

    return NO_SPACE_MESSAGE if spot.nil?

    park_car(car, spot)
    parking_status(car, spot.to_s)
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return 'Car not found' if plate.nil?

    spot, car = find_car(plate)

    return 'Car not found' if car.nil?

    @parking_spots[spot].delete(car)
    refresh_available!
    exit_status(plate)
  end

  def total_occupied
    @parking_spots.values.map(&:size).reduce(0, :+)
  end

  def total_available
    @small + @medium + @large
  end

  def garage_status
    {
      small_available: @small,
      medium_available: @medium,
      large_available: @large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def capacity
    @capacity.dup
  end

  def shuffle_medium(car = nil)
    normalized_car = normalize_car_hash(car, 'medium')
    return NO_SPACE_MESSAGE if normalized_car.nil?

    compact_for_medium!
    spot = find_spot_for('medium')
    return NO_SPACE_MESSAGE if spot.nil?

    park_car(normalized_car, spot)
    parking_status(normalized_car, spot.to_s)
  end

  def shuffle_large(car = nil)
    normalized_car = normalize_car_hash(car, 'large')
    return NO_SPACE_MESSAGE if normalized_car.nil?

    compact_for_large!
    spot = find_spot_for('large')
    return NO_SPACE_MESSAGE if spot.nil?

    park_car(normalized_car, spot)
    parking_status(normalized_car, spot.to_s)
  end

  def parking_status(car = nil, space = nil)
    return NO_SPACE_MESSAGE if car.nil? || space.nil?

    plate = car.is_a?(Hash) ? car[:plate] : car
    plate = normalize_plate(plate)
    return NO_SPACE_MESSAGE if plate.nil?

    "car with license plate no. #{plate} is parked at #{space}"
  end

  def exit_status(plate = nil)
    normalized_plate = normalize_plate(plate)
    return 'Car not found' if normalized_plate.nil?

    "car with license plate no. #{normalized_plate} exited"
  end

  private

  def nonnegative_integer(value)
    integer = Integer(value)
    integer.negative? ? 0 : integer
  rescue ArgumentError, TypeError
    0
  end

  def normalize_plate(value)
    plate = value.to_s.strip
    plate.empty? ? nil : plate
  rescue StandardError
    nil
  end

  def normalize_size(value)
    size = value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  rescue StandardError
    nil
  end

  def normalize_car_hash(car, default_size)
    return nil unless car.is_a?(Hash)

    plate =
      if car.key?(:plate)
        car[:plate]
      elsif car.key?('plate')
        car['plate']
      elsif car.key?(:license_plate)
        car[:license_plate]
      elsif car.key?('license_plate')
        car['license_plate']
      elsif car.key?(:license_plate_no)
        car[:license_plate_no]
      else
        car['license_plate_no']
      end

    size =
      if car.key?(:size)
        car[:size]
      elsif car.key?('size')
        car['size']
      elsif car.key?(:car_size)
        car[:car_size]
      else
        car['car_size']
      end

    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size) || default_size

    return nil if normalized_plate.nil?
    return nil unless VALID_SIZES.include?(normalized_size)
    return nil if parked?(normalized_plate)

    { plate: normalized_plate, size: normalized_size }
  end

  def available_count(spot)
    [@capacity[spot] - @parking_spots[spot].size, 0].max
  end

  def refresh_available!
    @small = available_count(:small)
    @medium = available_count(:medium)
    @large = available_count(:large)
  end

  def park_car(car, spot)
    @parking_spots[spot] << car
    refresh_available!
  end

  def find_spot_for(size)
    SPOT_ORDER.fetch(size, []).find { |spot| available_count(spot).positive? }
  end

  def find_car(plate)
    @parking_spots.each do |spot, cars|
      car = cars.find { |parked_car| parked_car[:plate] == plate }
      return [spot, car] if car
    end

    [nil, nil]
  end

  def parked?(plate)
    !find_car(plate).last.nil?
  end

  def move_first_car(car_size, from_spot, to_spot)
    return false unless available_count(to_spot).positive?

    car = @parking_spots[from_spot].find { |parked_car| parked_car[:size] == car_size }
    return false if car.nil?

    @parking_spots[from_spot].delete(car)
    @parking_spots[to_spot] << car
    refresh_available!
    true
  end

  def compact_for_medium!
    loop do
      moved = false

      if available_count(:small).positive?
        moved = move_first_car('small', :medium, :small)
        moved ||= move_first_car('small', :large, :small)
      end

      next if moved

      if available_count(:medium).positive?
        moved = move_first_car('medium', :large, :medium)
        moved ||= move_first_car('small', :large, :medium)
      end

      break unless moved
    end

    refresh_available!
  end

  def compact_for_large!
    loop do
      moved = false

      if available_count(:small).positive?
        moved = move_first_car('small', :large, :small)
        moved ||= move_first_car('small', :medium, :small)
      end

      next if moved

      if available_count(:medium).positive?
        moved = move_first_car('medium', :large, :medium)
        moved ||= move_first_car('small', :large, :medium)
      end

      break unless moved
    end

    refresh_available!
  end
end

class ParkingTicket
  VALID_SIZES = %w[small medium large].freeze
  @@issued_ticket_ids = {}

  attr_reader :id, :ticket_id, :entry_time, :license_plate, :license_plate_no, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @ticket_id = @id
    @license_plate = normalize_license_plate(license_plate)
    @license_plate_no = @license_plate
    @car_size = normalize_car_size(car_size)
    @entry_time = normalize_time(entry_time)
  end

  def duration_hours(reference_time = Time.now)
    duration = (reference_time - @entry_time) / 3600.0
    duration.negative? ? 0.0 : duration.to_f
  rescue StandardError
    0.0
  end

  def valid?(reference_time = Time.now)
    duration_hours(reference_time) <= 24.0
  end

  private

  def generate_ticket_id
    loop do
      ticket_id = "TK-#{SecureRandom.uuid}"
      next if @@issued_ticket_ids[ticket_id]

      @@issued_ticket_ids[ticket_id] = true
      return ticket_id
    end
  end

  def normalize_license_plate(value)
    value.to_s.strip
  rescue StandardError
    ''
  end

  def normalize_car_size(value)
    size = value.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : size
  rescue StandardError
    ''
  end

  def normalize_time(value)
    return value if value.is_a?(Time)
    return Time.at(value) if value.is_a?(Numeric)

    Time.parse(value.to_s)
  rescue StandardError
    Time.now
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

    return 0.0 if size.nil? || duration.nil?
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    billable_hours = (duration - GRACE_PERIOD_HOURS).ceil
    billable_hours = 1 if billable_hours < 1

    fee = billable_hours * RATES[size]
    [fee, MAX_FEE[size]].min.to_f
  end

  def calculate__fee(car_size, duration_hours)
    calculate_fee(car_size, duration_hours)
  end

  private

  def normalize_size(value)
    size = value.to_s.strip.downcase
    RATES.key?(size) ? size : nil
  rescue StandardError
    nil
  end

  def normalize_duration(value)
    duration = Float(value)
    return nil unless duration.finite?
    return nil if duration.negative?

    duration
  rescue ArgumentError, TypeError
    nil
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(
    small_spots_count = nil,
    medium_spots_count = nil,
    large_spots_count = nil,
    small_spots: nil,
    medium_spots: nil,
    large_spots: nil
  )
    if small_spots_count.is_a?(Hash)
      options = small_spots_count
      small_spots ||= options[:small_spots] || options['small_spots'] || options[:small] || options['small']
      medium_spots ||= options[:medium_spots] || options['medium_spots'] || options[:medium] || options['medium']
      large_spots ||= options[:large_spots] || options['large_spots'] || options[:large] || options['large']
      small_spots_count = nil
    end

    small_count = small_spots.nil? ? small_spots_count : small_spots
    medium_count = medium_spots.nil? ? medium_spots_count : medium_spots
    large_count = large_spots.nil? ? large_spots_count : large_spots

    @garage = ParkingGarage.new(small_count || 0, medium_count || 0, large_count || 0)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
    @tix_in_flight = @active_tickets
  end

  def admit_car(plate, size)
    normalized_plate = normalize_plate(plate)
    normalized_size = normalize_size(size)

    return { success: false, message: ParkingGarage::NO_SPACE_MESSAGE } if normalized_plate.nil? || normalized_size.nil?
    return { success: false, message: 'Car already parked' } if @active_tickets.key?(normalized_plate)

    message = @garage.admit_car(normalized_plate, normalized_size)

    if message.include?('parked')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message }
    end
  end

  def exit_car(plate)
    normalized_plate = normalize_plate(plate)
    return { success: false, message: 'No active ticket found' } if normalized_plate.nil?

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'No active ticket found' } if ticket.nil?

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    return { success: false, message: message } unless message.include?('exited')

    @active_tickets.delete(normalized_plate)

    {
      success: true,
      message: message,
      fee: fee.to_f,
      duration_hours: duration.to_f
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.total_occupied,
      total_available: @garage.total_available
    }
  end

  def find_ticket(plate)
    normalized_plate = normalize_plate(plate)
    return nil if normalized_plate.nil?

    @active_tickets[normalized_plate]
  end

  private

  def normalize_plate(value)
    plate = value.to_s.strip
    plate.empty? ? nil : plate
  rescue StandardError
    nil
  end

  def normalize_size(value)
    size = value.to_s.strip.downcase
    ParkingGarage::VALID_SIZES.include?(size) ? size : nil
  rescue StandardError
    nil
  end
end