require 'securerandom'

module ParkingInput
  VALID_SIZES = %w[small medium large].freeze

  def self.normalize_license_plate(license_plate)
    return nil if license_plate.nil?

    plate = license_plate.to_s.strip
    plate.empty? ? nil : plate
  end

  def self.normalize_car_size(car_size)
    return nil if car_size.nil?

    size = car_size.to_s.strip.downcase
    VALID_SIZES.include?(size) ? size : nil
  end

  def self.normalize_count(count)
    value = count.to_i
    value.negative? ? 0 : value
  rescue StandardError
    0
  end

  def self.numeric_duration(duration)
    value = Float(duration)
    value.finite? && value.positive? ? value : 0.0
  rescue StandardError, TypeError
    0.0
  end
end

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = ParkingInput.normalize_count(small)
    @medium = ParkingInput.normalize_count(medium)
    @large = ParkingInput.normalize_count(large)

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = ParkingInput.normalize_license_plate(license_plate_no)
    size = ParkingInput.normalize_car_size(car_size)

    return 'Invalid license plate' unless plate
    return 'Invalid car size' unless size
    return 'Car already parked' if parked?(plate)

    car = { plate: plate, size: size }

    case size
    when 'small'
      park_in_first_available(car, %i[small medium large])
    when 'medium'
      park_in_first_available(car, %i[medium large]) || shuffle_medium(car)
    when 'large'
      park_in_first_available(car, %i[large]) || shuffle_large(car)
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = ParkingInput.normalize_license_plate(license_plate_no)
    return 'Car not found' unless plate

    spot_type, car = find_car_with_spot(plate)
    return 'Car not found' unless car

    @parking_spots[spot_type].delete(car)
    increment_available(spot_type)

    "car with license plate no. #{plate} exited"
  end

  def total_occupied
    @parking_spots.values.sum(&:size)
  end

  def total_available
    @small + @medium + @large
  end

  def status
    {
      small_available: @small,
      medium_available: @medium,
      large_available: @large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  private

  def parked?(plate)
    !!find_car_with_spot(plate).last
  end

  def find_car_with_spot(plate)
    @parking_spots.each do |spot_type, cars|
      car = cars.find { |parked_car| parked_car[:plate] == plate }
      return [spot_type, car] if car
    end

    [nil, nil]
  end

  def park_in_first_available(car, preferred_spots)
    spot = preferred_spots.find { |spot_type| available_count(spot_type).positive? }
    return nil unless spot

    park_car(car, spot)
  end

  def park_car(car, spot_type)
    @parking_spots[spot_type] << car.merge(spot_type: spot_type)
    decrement_available(spot_type)

    parking_status(car, spot_type.to_s)
  end

  def move_car(car, from_spot, to_spot)
    return false unless car
    return false unless available_count(to_spot).positive?

    @parking_spots[from_spot].delete(car)
    increment_available(from_spot)

    car[:spot_type] = to_spot
    @parking_spots[to_spot] << car
    decrement_available(to_spot)

    true
  end

  def shuffle_medium(car)
    small_car_in_medium = @parking_spots[:medium].find { |parked_car| parked_car[:size] == 'small' }

    if small_car_in_medium && @small.positive?
      move_car(small_car_in_medium, :medium, :small)
      return park_car(car, :medium)
    end

    small_car_in_large = @parking_spots[:large].find { |parked_car| parked_car[:size] == 'small' }

    if small_car_in_large && @small.positive?
      move_car(small_car_in_large, :large, :small)
      return park_car(car, :large)
    end

    if small_car_in_large && @medium.positive?
      move_car(small_car_in_large, :large, :medium)
      return park_car(car, :large)
    end

    'No space available'
  end

  def shuffle_large(car)
    medium_car_in_large = @parking_spots[:large].find { |parked_car| parked_car[:size] == 'medium' }

    if medium_car_in_large && @medium.positive?
      move_car(medium_car_in_large, :large, :medium)
      return park_car(car, :large)
    end

    small_car_in_large = @parking_spots[:large].find { |parked_car| parked_car[:size] == 'small' }

    if small_car_in_large && @small.positive?
      move_car(small_car_in_large, :large, :small)
      return park_car(car, :large)
    end

    if small_car_in_large && @medium.positive?
      move_car(small_car_in_large, :large, :medium)
      return park_car(car, :large)
    end

    small_car_in_medium = @parking_spots[:medium].find { |parked_car| parked_car[:size] == 'small' }

    if medium_car_in_large && small_car_in_medium && @small.positive?
      move_car(small_car_in_medium, :medium, :small)
      move_car(medium_car_in_large, :large, :medium)
      return park_car(car, :large)
    end

    'No space available'
  end

  def available_count(spot_type)
    case spot_type
    when :small then @small
    when :medium then @medium
    when :large then @large
    else 0
    end
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

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end
end

class ParkingTicket
  attr_reader :id, :ticket_id, :entry_time, :license_plate, :license_plate_no, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @ticket_id = @id
    @license_plate = ParkingInput.normalize_license_plate(license_plate).to_s
    @license_plate_no = @license_plate
    @car_size = ParkingInput.normalize_car_size(car_size) || car_size.to_s.strip.downcase
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    duration = (Time.now - @entry_time) / 3600.0
    duration.negative? ? 0.0 : duration
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
    size = ParkingInput.normalize_car_size(car_size)
    duration = ParkingInput.numeric_duration(duration_hours)

    return 0.0 unless size
    return 0.0 if duration <= GRACE_PERIOD_HOURS

    billable_hours = duration.ceil
    total = billable_hours * RATES[size]

    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil, **kwargs)
    small_spots = kwargs[:small_spots] if kwargs.key?(:small_spots)
    medium_spots = kwargs[:medium_spots] if kwargs.key?(:medium_spots)
    large_spots = kwargs[:large_spots] if kwargs.key?(:large_spots)

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = ParkingInput.normalize_license_plate(plate)
    normalized_size = ParkingInput.normalize_car_size(size)

    return { success: false, message: 'Invalid license plate' } unless normalized_plate
    return { success: false, message: 'Invalid car size' } unless normalized_size
    return { success: false, message: 'Car already parked' } if @active_tickets.key?(normalized_plate)

    message = @garage.admit_car(normalized_plate, normalized_size)

    if message.include?('is parked at')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket

      {
        success: true,
        message: message,
        ticket: ticket
      }
    else
      {
        success: false,
        message: message
      }
    end
  end

  def exit_car(plate)
    normalized_plate = ParkingInput.normalize_license_plate(plate)
    return { success: false, message: 'Invalid license plate' } unless normalized_plate

    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)

    if message.include?('exited')
      @active_tickets.delete(normalized_plate)

      {
        success: true,
        message: message,
        fee: fee,
        duration_hours: duration
      }
    else
      {
        success: false,
        message: message
      }
    end
  end

  def garage_status
    @garage.status
  end

  def find_ticket(plate)
    normalized_plate = ParkingInput.normalize_license_plate(plate)
    return nil unless normalized_plate

    @active_tickets[normalized_plate]
  end
end