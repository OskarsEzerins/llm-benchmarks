require 'securerandom'

module ParkingValidation
  SIZES = %w[small medium large].freeze

  def self.plate(value)
    value.to_s.strip
  end

  def self.size(value)
    value.to_s.strip.downcase
  end

  def self.capacity(value)
    [Integer(value), 0].max
  rescue ArgumentError, TypeError, RangeError
    0
  end
end

class ParkingGarage
  attr_reader :parking_spots

  def initialize(small, medium, large)
    @capacities = {
      'small' => ParkingValidation.capacity(small),
      'medium' => ParkingValidation.capacity(medium),
      'large' => ParkingValidation.capacity(large)
    }
    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def small
    available('small')
  end

  def medium
    available('medium')
  end

  def large
    available('large')
  end

  def admit_car(license_plate_no, car_size)
    plate = ParkingValidation.plate(license_plate_no)
    size = ParkingValidation.size(car_size)

    return 'Invalid license plate' if plate.empty?
    return 'Invalid car size' unless ParkingValidation::SIZES.include?(size)
    return "car with license plate no. #{plate} is already parked" if parked?(plate)

    car = { plate: plate, size: size }
    eligible = ParkingValidation::SIZES.drop(ParkingValidation::SIZES.index(size))

    spot = eligible.find { |type| available(type).positive? }
    spot ||= eligible.find { |type| free_spot(type) }

    return parking_status unless spot

    spots_for(spot) << car
    parking_status(car, spot)
  end

  def exit_car(license_plate_no)
    plate = ParkingValidation.plate(license_plate_no)
    return 'Invalid license plate' if plate.empty?

    @parking_spots.each_value do |cars|
      index = cars.index { |car| car[:plate] == plate }
      next unless index

      cars.delete_at(index)
      return exit_status(plate)
    end

    exit_status
  end

  def parked?(license_plate_no)
    plate = ParkingValidation.plate(license_plate_no)
    @parking_spots.values.any? do |cars|
      cars.any? { |car| car[:plate] == plate }
    end
  end

  def shuffle_medium(car)
    admit_car(car[:plate], 'medium')
  end

  def shuffle_large(car)
    admit_car(car[:plate], 'large')
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

  def spots_for(type)
    @parking_spots.fetch(:"#{type}_spot")
  end

  def available(type)
    @capacities.fetch(type) - spots_for(type).length
  end

  # Recursively move smaller cars down to free the requested spot.
  # Moves only occur when the entire relocation chain can succeed.
  def free_spot(type)
    return true if available(type).positive?

    target_index = ParkingValidation::SIZES.index(type)

    spots_for(type).each do |car|
      car_index = ParkingValidation::SIZES.index(car[:size])
      next unless car_index < target_index

      ParkingValidation::SIZES[car_index...target_index].each do |destination|
        next unless free_spot(destination)

        spots_for(type).delete(car)
        spots_for(destination) << car
        return true
      end
    end

    false
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :entry_time, :car_size

  alias ticket_id id
  alias license_plate_no license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = ParkingValidation.plate(license_plate)
    @car_size = ParkingValidation.size(car_size)
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    !@license_plate.empty? &&
      ParkingValidation::SIZES.include?(@car_size) &&
      @entry_time <= Time.now &&
      duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    SecureRandom.uuid
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = ParkingValidation.size(car_size)
    return 0.0 unless RATES.key?(size)

    begin
      duration = Float(duration_hours)
    rescue ArgumentError, TypeError, RangeError
      return 0.0
    end

    return 0.0 unless duration.finite?
    return 0.0 if duration <= GRACE_PERIOD

    [duration.ceil * RATES.fetch(size), MAX_FEE.fetch(size)].min.to_f
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    plate = ParkingValidation.plate(plate)
    size = ParkingValidation.size(size)

    return { success: false, message: 'Invalid license plate' } if plate.empty?
    unless ParkingValidation::SIZES.include?(size)
      return { success: false, message: 'Invalid car size' }
    end

    if @active_tickets.key?(plate) || @garage.parked?(plate)
      return {
        success: false,
        message: "car with license plate no. #{plate} is already parked"
      }
    end

    message = @garage.admit_car(plate, size)
    unless @garage.parked?(plate)
      return { success: false, message: message }
    end

    ticket = ParkingTicket.new(plate, size)
    @active_tickets[plate] = ticket
    { success: true, message: message, ticket: ticket }
  end

  def exit_car(plate)
    plate = ParkingValidation.plate(plate)
    return { success: false, message: 'Invalid license plate' } if plate.empty?

    ticket = @active_tickets[plate]
    return { success: false, message: 'Ticket not found' } unless ticket

    unless @garage.parked?(plate)
      return { success: false, message: 'Car not found' }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message = @garage.exit_car(plate)
    @active_tickets.delete(plate)

    {
      success: true,
      message: message,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.parking_spots.values.sum(&:length),
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[ParkingValidation.plate(plate)]
  end
end