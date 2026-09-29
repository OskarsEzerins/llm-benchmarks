require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  SIZES = %w[small medium large].freeze

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
    return parking_status if license_plate_no.nil?
    plate = license_plate_no.to_s
    return parking_status if plate.strip.empty?
    return parking_status if car_size.nil?
    size = car_size.to_s.strip.downcase
    return parking_status unless SIZES.include?(size)
    # already parked
    return parking_status if find_car(plate)

    kar = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        place(kar, :small)
      elsif @medium > 0
        place(kar, :medium)
      elsif @large > 0
        place(kar, :large)
      else
        parking_status
      end
    when 'medium'
      if @medium > 0
        place(kar, :medium)
      elsif @large > 0
        place(kar, :large)
      else
        shuffle_medium(kar)
      end
    when 'large'
      if @large > 0
        place(kar, :large)
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    return exit_status if license_plate_no.nil?
    plate = license_plate_no.to_s
    spot = find_car(plate)
    return exit_status unless spot

    car = @parking_spots[spot].find { |c| c[:plate] == plate }
    @parking_spots[spot].delete(car)
    case spot
    when :small  then @small += 1
    when :medium then @medium += 1
    when :large  then @large += 1
    end
    exit_status(plate)
  end

  def shuffle_medium(kar)
    # a medium car in a large spot can't move to small; nothing to shuffle
    parking_status
  end

  def shuffle_large(kar)
    # move a small car from a large spot to a free medium or small spot
    if @medium > 0
      victim = @parking_spots[:large].find { |c| c[:size] == 'medium' || c[:size] == 'small' }
      if victim
        @parking_spots[:large].delete(victim)
        @parking_spots[:medium] << victim
        @medium -= 1
        @parking_spots[:large] << kar
        return parking_status(kar, 'large')
      end
    end
    if @small > 0
      victim = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if victim
        @parking_spots[:large].delete(victim)
        @parking_spots[:small] << victim
        @small -= 1
        @parking_spots[:large] << kar
        return parking_status(kar, 'large')
      end
    end
    parking_status
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      "car not found"
    end
  end

  private

  def place(kar, spot)
    @parking_spots[spot] << kar
    case spot
    when :small  then @small -= 1
    when :medium then @medium -= 1
    when :large  then @large -= 1
    end
    parking_status(kar, spot.to_s)
  end

  def find_car(plate)
    @parking_spots.each do |spot, cars|
      return spot if cars.any? { |c| c[:plate] == plate }
    end
    nil
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
    duration_hours <= 24
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
    return 0.0 if car_size.nil?
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 unless duration_hours.is_a?(Numeric)
    return 0.0 if duration_hours.respond_to?(:nan?) && duration_hours.nan?
    return 0.0 if duration_hours <= GRACE_PERIOD

    hours = duration_hours.ceil
    total = hours * RATES[size]
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
    verdict = @garage.admit_car(plate, size)

    if verdict.to_s.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    key = plate.to_s
    ticket = @tickets[key]
    return { success: false, message: 'No ticket found for license plate no. ' + key } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(key)

    @tickets.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration.round(1) }
  end

  def garage_status
    small = @garage.small
    medium = @garage.medium
    large = @garage.large
    occupied = @garage.parking_spots.values.map(&:size).sum
    {
      small_available: small,
      medium_available: medium,
      large_available: large,
      total_occupied: occupied,
      total_available: small + medium + large
    }
  end

  def find_ticket(plate)
    @tickets.fetch(plate.to_s, nil)
  end
end