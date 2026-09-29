require 'securerandom'

class ParkingGarage
  SIZES = %w[small medium large].freeze
  NO_SPACE = 'No space available'.freeze

  PREFERENCES = {
    'small'  => %w[small medium large],
    'medium' => %w[medium large],
    'large'  => %w[large]
  }.freeze

  attr_reader :parking_spots

  def initialize(small, medium, large)
    @available = {
      'small'  => [small.to_i, 0].max,
      'medium' => [medium.to_i, 0].max,
      'large'  => [large.to_i, 0].max
    }
    @capacity = @available.dup
    @parking_spots = {
      small_spot:  [],
      medium_spot: [],
      large_spot:  []
    }
  end

  def small
    @available['small']
  end

  def medium
    @available['medium']
  end

  def large
    @available['large']
  end

  def capacity(type = nil)
    type ? @capacity[type.to_s] : @capacity.values.sum
  end

  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size  = normalize_size(car_size)
    return parking_status if plate.nil? || size.nil?
    return "car with license plate no. #{plate} is already in the garage" if find_car(plate)

    kar = { plate: plate, size: size }

    spot = PREFERENCES[size].find { |s| @available[s] > 0 }
    if spot
      park(kar, spot)
      return parking_status(kar, spot)
    end

    case size
    when 'medium' then shuffle_medium(kar)
    when 'large'  then shuffle_large(kar)
    else parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return exit_status if plate.nil?

    SIZES.each do |spot|
      car = @parking_spots[spot_key(spot)].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot_key(spot)].delete(car)
      @available[spot] += 1
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(kar)
    %w[medium large].each do |spot|
      if make_room(spot, 'small' => %w[small])
        park(kar, spot)
        return parking_status(kar, spot)
      end
    end
    parking_status
  end

  def shuffle_large(kar)
    dest_map = { 'medium' => %w[medium], 'small' => %w[small medium] }
    if make_room('large', dest_map)
      park(kar, 'large')
      return parking_status(kar, 'large')
    end
    parking_status
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      NO_SPACE
    end
  end

  def exit_status(plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      'car not found'
    end
  end

  def find_car(plate)
    plate = normalize_plate(plate)
    return nil if plate.nil?

    @parking_spots.each_value do |cars|
      car = cars.find { |c| c[:plate] == plate }
      return car if car
    end
    nil
  end

  private

  def spot_key(type)
    "#{type}_spot".to_sym
  end

  def normalize_plate(plate)
    return nil if plate.nil?

    str = plate.to_s.strip
    str.empty? ? nil : str
  end

  def normalize_size(size)
    return nil if size.nil?

    str = size.to_s.strip.downcase
    SIZES.include?(str) ? str : nil
  end

  def park(kar, spot)
    @parking_spots[spot_key(spot)] << kar
    @available[spot] -= 1
  end

  # Tries to move one car out of +spot+ into a free spot of a different type.
  # dest_map: car size => list of acceptable destination spot types.
  def make_room(spot, dest_map)
    @parking_spots[spot_key(spot)].each do |car|
      dests = dest_map[car[:size]] || []
      dest  = dests.find { |d| @available[d] > 0 }
      next unless dest

      @parking_spots[spot_key(spot)].delete(car)
      @available[spot] += 1
      park(car, dest)
      return true
    end
    false
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.strip.downcase
    @entry_time    = entry_time || Time.now
  end

  def license
    @license_plate
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if car_size.nil? || duration_hours.nil?
    return 0.0 unless duration_hours.is_a?(Numeric)

    duration = duration_hours.to_f
    return 0.0 if duration.nan? || duration < 0
    return 0.0 if duration <= GRACE_PERIOD

    size = car_size.to_s.strip.downcase
    rate = RATES[size]
    return 0.0 unless rate

    hours = duration.infinite? ? 24 : duration.ceil
    total = hours * rate
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    verdict = @garage.admit_car(plate, size)

    if verdict.to_s.include?('is parked at')
      key    = plate.to_s.strip
      ticket = ParkingTicket.new(key, size)
      @tix_in_flight[key] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    key    = plate.to_s.strip
    ticket = @tix_in_flight[key]
    unless ticket
      return { success: false, message: "car with license plate no. #{key} not found" }
    end

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(key)

    @tix_in_flight.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration.round(2) }
  end

  def garage_status
    small_a  = @garage.small
    medium_a = @garage.medium
    large_a  = @garage.large
    total_a  = small_a + medium_a + large_a

    {
      small_available:  small_a,
      medium_available: medium_a,
      large_available:  large_a,
      total_occupied:   @garage.capacity - total_a,
      total_available:  total_a
    }
  end

  def find_ticket(plate)
    @tix_in_flight.fetch(plate.to_s.strip, nil)
  end
end