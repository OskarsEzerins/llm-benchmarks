require 'securerandom'

class ParkingGarage
  attr_reader :available_small, :available_medium, :available_large, :parking_spots

  def initialize(small, medium, large)
    @available_small   = small.to_i
    @available_medium  = medium.to_i
    @available_large   = large.to_i
    @parking_spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate, car_size)
    plate = license_plate.to_s.strip
    return 'Invalid license plate' if plate.empty?

    size = car_size.to_s.downcase.strip
    return 'Invalid car size' unless %w[small medium large].include?(size)

    case size
    when 'small'
      if @available_small > 0
        park_car(plate, :small)
      elsif @available_medium > 0
        park_car(plate, :medium)
      elsif @available_large > 0
        park_car(plate, :large)
      else
        'No space available'
      end
    when 'medium'
      if @available_medium > 0
        park_car(plate, :medium)
      elsif @available_large > 0
        park_car(plate, :large)
      else
        'No space available'
      end
    when 'large'
      if @available_large > 0
        park_car(plate, :large)
      else
        msg = shuffle_for_large(plate)
        msg || 'No space available'
      end
    end
  end

  def exit_car(license_plate)
    plate = license_plate.to_s.strip
    return 'Car not found' if plate.empty?

    spot_type = nil
    @parking_spots.each do |type, cars|
      if cars.delete(plate)
        spot_type = type
        case type
        when :small
          @available_small += 1
        when :medium
          @available_medium += 1
        when :large
          @available_large += 1
        end
        break
      end
    end

    spot_type ? "car with license plate no. #{plate} exited" : 'Car not found'
  end

  def total_occupied
    @parking_spots.values.map(&:size).sum
  end

  def total_available
    @available_small + @available_medium + @available_large
  end

  private

  def park_car(plate, spot_type)
    case spot_type
    when :small
      @available_small -= 1
    when :medium
      @available_medium -= 1
    when :large
      @available_large -= 1
    end
    @parking_spots[spot_type] << plate
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def shuffle_for_large(plate)
    return nil unless @available_small > 0
    medium_cars = @parking_spots[:medium]
    return nil if medium_cars.empty?

    victim = medium_cars.shift
    @available_medium += 1
    @parking_spots[:small] << victim
    @available_small -= 1
    park_car(plate, :large)
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase.strip
    @entry_time = entry_time
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0].max
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  RATES = { small: 2.0, medium: 3.0, large: 5.0 }
  MAX_FEE = { small: 20.0, medium: 30.0, large: 50.0 }

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase.strip
    return 0.0 unless %w[small medium large].include?(size)
    return 0.0 unless duration_hours.is_a?(Numeric) && duration_hours >= 0

    return 0.0 if duration_hours <= 0.25

    hours = duration_hours.ceil
    rate = RATES[size.to_sym]
    total = hours * rate
    [total, MAX_FEE[size.to_sym]].min
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    return { success: false, message: 'Invalid license plate' } if plate.nil? || plate.to_s.strip.empty?
    return { success: false, message: 'Invalid car size' } unless %w[small medium large].include?(size.to_s.downcase.strip)

    result_msg = @garage.admit_car(plate, size)
    if result_msg.start_with?('car with license plate no.')
      ticket = ParkingTicket.new(plate, size)
      @tickets[plate.to_s] = ticket
      { success: true, message: result_msg, ticket: ticket }
    else
      { success: false, message: result_msg }
    end
  end

  def exit_car(plate, duration_override = nil)
    return { success: false, message: 'Invalid license plate' } if plate.nil? || plate.to_s.strip.empty?

    ticket = @tickets.delete(plate.to_s)
    return { success: false, message: "No ticket found for license plate no. #{plate}" } unless ticket

    exit_msg = @garage.exit_car(plate)
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration_override || ticket.duration_hours)

    { success: true, message: exit_msg, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.available_small,
      medium_available: @garage.available_medium,
      large_available: @garage.available_large,
      total_occupied: @garage.total_occupied,
      total_available: @garage.total_available,
      active_tickets: @tickets.size
    }
  end

  def find_ticket(plate)
    @tickets[plate.to_s]
  end
end