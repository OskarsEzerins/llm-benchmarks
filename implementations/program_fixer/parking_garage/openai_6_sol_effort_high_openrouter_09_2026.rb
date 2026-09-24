require 'securerandom'

class ParkingGarage
  SIZES = %w[small medium large].freeze
  SPOT_CHOICES = {
    'small' => %w[small medium large].freeze,
    'medium' => %w[medium large].freeze,
    'large' => %w[large].freeze
  }.freeze

  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large = [large.to_i, 0].max

    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.strip.downcase

    return 'Invalid license plate' if plate.empty?
    return 'Invalid car size' unless SIZES.include?(size)
    return 'Car already parked' if parked?(plate)

    car = { plate: plate, size: size }

    SPOT_CHOICES.fetch(size).each do |spot_type|
      return park(car, spot_type) if available(spot_type).positive?
    end

    case size
    when 'medium' then shuffle_medium(car)
    when 'large' then shuffle_large(car)
    else parking_status
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip

    SIZES.each do |spot_type|
      cars = spots(spot_type)
      index = cars.index { |car| car[:plate] == plate }
      next unless index

      cars.delete_at(index)
      change_available(spot_type, 1)
      return exit_status(plate)
    end

    exit_status
  end

  def shuffle_medium(car)
    shuffle_into(car, SPOT_CHOICES.fetch('medium'), 'medium')
  end

  def shuffle_large(car)
    shuffle_into(car, SPOT_CHOICES.fetch('large'), 'large')
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

  def spots(spot_type)
    @parking_spots.fetch(:"#{spot_type}_spot")
  end

  def available(spot_type)
    public_send(spot_type)
  end

  def change_available(spot_type, amount)
    instance_variable_set(:"@#{spot_type}", available(spot_type) + amount)
  end

  def parked?(plate)
    @parking_spots.values.any? do |cars|
      cars.any? { |car| car[:plate] == plate }
    end
  end

  def park(car, spot_type)
    spots(spot_type) << car
    change_available(spot_type, -1)
    parking_status(car, spot_type)
  end

  def shuffle_into(car, choices, expected_size)
    return parking_status unless car.is_a?(Hash)

    plate = car[:plate].to_s.strip
    size = car[:size].to_s.strip.downcase
    return 'Invalid license plate' if plate.empty?
    return 'Invalid car size' unless size == expected_size
    return 'Car already parked' if parked?(plate)

    normalized_car = { plate: plate, size: size }

    choices.each do |spot_type|
      plan = relocation_plan(spot_type)
      next unless plan

      plan.each do |occupant, from, to|
        spots(from).delete(occupant)
        change_available(from, 1)
        spots(to) << occupant
        change_available(to, -1)
      end

      return park(normalized_car, spot_type)
    end

    parking_status
  end

  # Find a sequence of moves that frees one spot of the requested type.
  # No cars are moved unless the entire sequence is possible.
  def relocation_plan(spot_type, visited = [])
    return [] if available(spot_type).positive?

    visited = visited + [spot_type]

    spots(spot_type).each do |occupant|
      SPOT_CHOICES.fetch(occupant[:size]).each do |destination|
        next if visited.include?(destination)

        preceding_moves = relocation_plan(destination, visited)
        return preceding_moves + [[occupant, spot_type, destination]] if preceding_moves
      end
    end

    nil
  end
end

class ParkingTicket
  SIZES = ParkingGarage::SIZES

  attr_reader :id, :license_plate, :entry_time, :car_size

  alias license_plate_no license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = "TK-#{SecureRandom.uuid}"
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time.is_a?(Time) ? entry_time : Time.now
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    !@license_plate.empty? && SIZES.include?(@car_size) && duration_hours < 24.0
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
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    duration = Float(duration_hours)
    return 0.0 unless duration.finite? && duration > 0.25

    full_days = (duration / 24.0).floor
    remaining_hours = duration - (full_days * 24.0)

    fee = full_days * MAX_FEE.fetch(size)
    fee += [remaining_hours.ceil * RATES.fetch(size), MAX_FEE.fetch(size)].min
    fee.to_f
  rescue ArgumentError, TypeError
    0.0
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(*counts, **options)
    small = counts[0] || options[:small_spots] || options[:small]
    medium = counts[1] || options[:medium_spots] || options[:medium]
    large = counts[2] || options[:large_spots] || options[:large]

    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    normalized_plate = plate.to_s.strip
    message = @garage.admit_car(plate, size)

    unless message.start_with?("car with license plate no. #{normalized_plate} is parked at ")
      return { success: false, message: message }
    end

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

    unless message == "car with license plate no. #{normalized_plate} exited"
      return { success: false, message: message }
    end

    @active_tickets.delete(normalized_plate)
    {
      success: true,
      message: message,
      fee: fee,
      duration_hours: duration
    }
  end

  def garage_status
    total_available = @garage.small + @garage.medium + @garage.large
    total_occupied = @garage.parking_spots.values.sum(&:size)

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end