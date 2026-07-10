require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

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
    plate = license_plate_no.to_s
    size = normalize_size(car_size)
    return 'No space available' unless valid_plate?(plate) && size

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small.positive?
        park(car, :small)
      elsif @medium.positive?
        park(car, :medium)
      elsif @large.positive?
        park(car, :large)
      else
        'No space available'
      end
    when 'medium'
      if @medium.positive?
        park(car, :medium)
      elsif @large.positive?
        park(car, :large)
      else
        'No space available'
      end
    when 'large'
      if @large.positive?
        park(car, :large)
      else
        shuffle_for_large(car)
      end
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s

    @parking_spots.each do |type, cars|
      car = cars.find { |item| item[:plate] == plate }
      next unless car

      cars.delete(car)
      increment_available(type)
      return "car with license plate no. #{plate} exited"
    end

    'Car not found'
  end

  def shuffle_medium(car)
    return park(car, :medium) if @medium.positive?

    'No space available'
  end

  def shuffle_large(car)
    shuffle_for_large(car)
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : 'Car not found'
  end

  private

  def normalize_size(size)
    value = size.to_s.downcase
    %w[small medium large].include?(value) ? value : nil
  end

  def valid_plate?(plate)
    !plate.strip.empty?
  end

  def park(car, type)
    @parking_spots[type] << car
    decrement_available(type)
    parking_status(car, type.to_s)
  end

  def decrement_available(type)
    case type
    when :small then @small -= 1
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
  end

  def increment_available(type)
    case type
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end
  end

  def shuffle_for_large(car)
    victim = @parking_spots[:large].find { |item| item[:size] == 'medium' }
    return 'No space available' unless victim && @medium.positive?

    @parking_spots[:large].delete(victim)
    @parking_spots[:medium] << victim
    @medium -= 1
    @large += 1
    park(car, :large)
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size = normalize_size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
  end

  def normalize_size(size)
    value = size.to_s.downcase
    %w[small medium large].include?(value) ? value : nil
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

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    duration = Float(duration_hours)
    return 0.0 unless RATES.key?(size) && duration.finite? && duration >= 0
    return 0.0 if duration <= 0.25

    hours = duration.ceil
    [hours * RATES[size], MAX_FEE[size]].min.to_f
  rescue ArgumentError, TypeError
    0.0
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(*args, small_spots: nil, medium_spots: nil, large_spots: nil)
    if args.length == 3
      small_spots, medium_spots, large_spots = args
    end

    @garage = ParkingGarage.new(small_spots || 0, medium_spots || 0, large_spots || 0)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    normalized_plate = plate.to_s
    result = @garage.admit_car(normalized_plate, size)

    if result.include?('is parked')
      ticket = ParkingTicket.new(normalized_plate, size)
      @tix_in_flight[normalized_plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    normalized_plate = plate.to_s
    ticket = @tix_in_flight[normalized_plate]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(normalized_plate)

    @tix_in_flight.delete(normalized_plate)

    {
      success: result.include?('exited'),
      message: result,
      fee: fee.to_f,
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
    @tix_in_flight[plate.to_s]
  end
end