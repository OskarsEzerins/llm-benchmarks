require 'securerandom'

class ParkingGarage
  SIZES = %w[small medium large].freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = capacity(small)
    @medium = capacity(medium)
    @large = capacity(large)

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase.strip

    return 'No space available' if plate.empty? || !SIZES.include?(size)
    return 'No space available' if parked?(plate)

    car = { plate: plate, size: size }

    eligible_spots(size).each do |spot_type|
      next unless available(spit_type = spot_type).positive? || vacate(spot_type)

      @parking_spots[spot_key(spot_type)] << car
      change_available(spot_type, -1)
      return "car with license plate no. #{plate} is parked at #{spot_type}"
    end

    'No space available'
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip

    SIZES.each do |spot_type|
      cars = @parking_spots[spot_key(spot_type)]
      index = cars.index { |car| car[:plate] == plate }
      next unless index

      cars.delete_at(index)
      change_available(spot_type, 1)
      return "car with license plate no. #{plate} exited"
    end

    'Car not found'
  end

  private

  def capacity(value)
    [Integer(value), 0].max
  rescue ArgumentError, TypeError
    0
  end

  def parked?(plate)
    @parking_spots.values.any? do |cars|
      cars.any? { |car| car[:plate] == plate }
    end
  end

  def eligible_spots(size)
    SIZES.drop(SIZES.index(size))
  end

  def spot_key(type)
    :"#{type}_spot"
  end

  def available(type)
    public_send(type)
  end

  def change_available(type, amount)
    instance_variable_set(:"@#{type}", available(type) + amount)
  end

  # Free a spot by moving one of its occupants into a smaller spot it fits.
  # Moves only toward smaller spots, so recursive shuffling cannot cycle.
  def vacate(spot_type)
    destination_types = SIZES.take(SIZES.index(spot_type))

    @parking_spots[spot_key(spot_type)].dup.each do |car|
      destination_types.each do |destination|
        next unless eligible_spots(car[:size]).include?(destination)
        next unless available(destination).positive? || vacate(destination)

        @parking_spots[spot_key(spot_type)].delete(car)
        @parking_spots[spot_key(destination)] << car
        change_available(spot_type, 1)
        change_available(destination, -1)
        return true
      end
    end

    false
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  alias license_plate_no license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase.strip
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration = duration_hours
    duration >= 0 && duration <= 24
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
    size = car_size.to_s.downcase.strip
    return 0.0 unless RATES.key?(size)

    duration = Float(duration_hours)
    return 0.0 unless duration.finite? && duration > 0.25

    full_days = (duration / 24).floor
    remaining_hours = duration - full_days * 24
    remaining_fee = [remaining_hours.ceil * RATES[size], MAX_FEE[size]].min

    (full_days * MAX_FEE[size] + remaining_fee).to_f
  rescue ArgumentError, TypeError
    0.0
  end
end

class ParkingGarageManager
  attr_reader :garage, :active_tickets

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = plate.to_s.strip
    if @active_tickets.key?(normalized_plate)
      return { success: false, message: 'Car already parked' }
    end

    message = @garage.admit_car(normalized_plate, size)
    return { success: false, message: message } if message == 'No space available'

    ticket = ParkingTicket.new(normalized_plate, size)
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
      total_occupied: @garage.parking_spots.values.sum(&:length),
      total_available: available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end