require 'securerandom'

class ParkingGarage
  SIZES = %w[small medium large].freeze
  ELIGIBLE_SPOTS = {
    'small' => %w[small medium large],
    'medium' => %w[medium large],
    'large' => %w[large]
  }.freeze

  attr_reader :parking_spots

  def initialize(small, medium, large)
    @capacities = {
      small: capacity(small),
      medium: capacity(medium),
      large: capacity(large)
    }
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def small
    available(:small)
  end

  def medium
    available(:medium)
  end

  def large
    available(:large)
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.strip.downcase
    return 'No space available' if plate.empty? || !SIZES.include?(size)
    return 'No space available' if parked?(plate)

    car = { plate: plate, size: size }
    ELIGIBLE_SPOTS[size].each do |spot|
      if make_space(spot.to_sym, [])
        @parking_spots[spot.to_sym] << car
        return parking_status(car, spot)
      end
    end

    'No space available'
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip

    @parking_spots.each_value do |cars|
      car = cars.find { |candidate| candidate[:plate] == plate }
      if car
        cars.delete(car)
        return exit_status(plate)
      end
    end

    'Car not found'
  end

  def parking_status(car = nil, space = nil)
    return 'No space available' unless car && space

    "car with license plate no. #{car[:plate]} is parked at #{space}"
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : 'Car not found'
  end

  private

  def capacity(value)
    [Integer(value), 0].max
  rescue ArgumentError, TypeError
    0
  end

  def available(spot)
    @capacities[spot] - @parking_spots[spot].length
  end

  def parked?(plate)
    @parking_spots.values.any? { |cars| cars.any? { |car| car[:plate] == plate } }
  end

  # Relocate an occupant only after space for it has been secured elsewhere.
  def make_space(spot, visited)
    return true if available(spot).positive?
    return false if visited.include?(spot)

    @parking_spots[spot].dup.each do |occupant|
      ELIGIBLE_SPOTS[occupant[:size]].each do |destination_name|
        destination = destination_name.to_sym
        next if destination == spot || visited.include?(destination)

        if make_space(destination, visited + [spot])
          @parking_spots[spot].delete(occupant)
          @parking_spots[destination] << occupant
          return true
        end
      end
    end

    false
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def license_plate_no
    @license_plate
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    duration_hours < 24.0
  end
end

class ParkingFeeCalculator
  RATES = { 'small' => 2.0, 'medium' => 3.0, 'large' => 5.0 }.freeze
  MAX_FEE = { 'small' => 20.0, 'medium' => 30.0, 'large' => 50.0 }.freeze

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    hours = Float(duration_hours)
    return 0.0 unless hours.finite? && hours > 0.25

    [hours.ceil * RATES[size], MAX_FEE[size]].min.to_f
  rescue ArgumentError, TypeError
    0.0
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = plate.to_s.strip
    normalized_size = size.to_s.strip.downcase
    return { success: false, message: 'Invalid license plate' } if normalized_plate.empty?
    unless ParkingGarage::SIZES.include?(normalized_size)
      return { success: false, message: 'Invalid car size' }
    end
    if @active_tickets.key?(normalized_plate)
      return { success: false, message: 'Car is already parked' }
    end

    message = @garage.admit_car(normalized_plate, normalized_size)
    return { success: false, message: message } if message == 'No space available'

    ticket = ParkingTicket.new(normalized_plate, normalized_size)
    @active_tickets[normalized_plate] = ticket
    { success: true, message: message, ticket: ticket }
  end

  def exit_car(plate)
    normalized_plate = plate.to_s.strip
    ticket = @active_tickets[normalized_plate]
    return { success: false, message: 'Car not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(normalized_plate)
    return { success: false, message: message } if message == 'Car not found'

    @active_tickets.delete(normalized_plate)
    { success: true, message: message, fee: fee, duration_hours: duration }
  end

  def garage_status
    available = @garage.small + @garage.medium + @garage.large
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @active_tickets.size,
      total_available: available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end