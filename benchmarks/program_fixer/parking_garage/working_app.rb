# frozen_string_literal: true

# https://github.com/pinkmoon25/valet-parking-management

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = small
    @medium = medium
    @large = large
    @parking_spots = {
      small_spot: [],
      medium_spot: [],
      large_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return 'No space available' if license_plate_no.nil? || car_size.nil?
    return 'No space available' if license_plate_no.to_s.strip.empty?
    return 'No space available' unless %w[small medium large].include?(car_size.downcase)

    normalized_size = car_size.downcase
    car = { car: license_plate_no, size: normalized_size }

    case normalized_size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << car
        @small -= 1
        "car with license plate no. #{car[:car]} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        "car with license plate no. #{car[:car]} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        "car with license plate no. #{car[:car]} is parked at large"
      else
        'No space available'
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        "car with license plate no. #{car[:car]} is parked at medium"
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        "car with license plate no. #{car[:car]} is parked at large"
      else
        shuffle_medium(car)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        "car with license plate no. #{car[:car]} is parked at large"
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    return 'Car not found!' if license_plate_no.nil?
    return 'Car not found!' if license_plate_no.to_s.strip.empty?

    small_car = @parking_spots[:small_spot].find { |car| car[:car].to_s == license_plate_no.to_s }
    medium_car = @parking_spots[:medium_spot].find { |car| car[:car].to_s == license_plate_no.to_s }
    large_car = @parking_spots[:large_spot].find { |car| car[:car].to_s == license_plate_no.to_s }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      "car with license plate no. #{license_plate_no} exited"
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      "car with license plate no. #{license_plate_no} exited"
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      "car with license plate no. #{license_plate_no} exited"
    else
      'Car not found!'
    end
  end

  private

  def shuffle_medium(car)
    if !@small.zero? && (@parking_spots[:medium_spot].any? { |parked_car| parked_car[:size] == 'small' } ||
                        @parking_spots[:large_spot].any? { |parked_car| parked_car[:size] == 'small' })

      small_at_medium = @parking_spots[:medium_spot].find { |parked_car| parked_car[:size] == 'small' }
      small_at_large = @parking_spots[:large_spot].find { |parked_car| parked_car[:size] == 'small' }

      if small_at_medium
        @parking_spots[:medium_spot].delete(small_at_medium)
        @parking_spots[:medium_spot] << car
        @parking_spots[:small_spot] << small_at_medium
        @small -= 1
        "car with license plate no. #{car[:car]} is parked at medium"
      elsif small_at_large
        @parking_spots[:large_spot].delete(small_at_large)
        @parking_spots[:large_spot] << car
        @parking_spots[:small_spot] << small_at_large
        @small -= 1
        "car with license plate no. #{car[:car]} is parked at large"
      else
        'No space available'
      end
    else
      'No space available'
    end
  end

  def shuffle_large(car)
    # Try to move medium car from large spot
    if !@medium.zero? && @parking_spots[:large_spot].any? { |parked_car| parked_car[:size] == 'medium' }
      medium_at_large = @parking_spots[:large_spot].find { |parked_car| parked_car[:size] == 'medium' }
      @parking_spots[:large_spot].delete(medium_at_large)
      @parking_spots[:large_spot] << car
      @parking_spots[:medium_spot] << medium_at_large
      @medium -= 1
      return "car with license plate no. #{car[:car]} is parked at large"
    end

    # Try to move small car from large spot
    if (!@small.zero? || !@medium.zero?) && @parking_spots[:large_spot].any? do |parked_car|
      parked_car[:size] == 'small'
    end
      small_at_large = @parking_spots[:large_spot].find { |parked_car| parked_car[:size] == 'small' }
      @parking_spots[:large_spot].delete(small_at_large)
      @parking_spots[:large_spot] << car

      if !@small.zero?
        @parking_spots[:small_spot] << small_at_large
        @small -= 1
      elsif !@medium.zero?
        @parking_spots[:medium_spot] << small_at_large
        @medium -= 1
      end

      return "car with license plate no. #{car[:car]} is parked at large"
    end

    'No space available'
  end
end

# Parking ticket management
class ParkingTicket
  attr_reader :ticket_id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @ticket_id = generate_ticket_id
    @license_plate = license_plate
    @car_size = car_size
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0 # Tickets expire after 24 hours
  end

  private

  def generate_ticket_id
    "T#{Time.now.to_i}#{rand(1000..9999)}"
  end
end

# Parking fee calculation
class ParkingFeeCalculator
  HOURLY_RATES = {
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }.freeze

  DAILY_MAXIMUMS = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  GRACE_PERIOD_HOURS = 0.25 # 15 minutes free

  def calculate_fee(car_size, duration_hours)
    raise ArgumentError, "Invalid car size: #{car_size}" unless HOURLY_RATES.key?(car_size)

    return 0.0 if duration_hours <= GRACE_PERIOD_HOURS

    billable_hours = duration_hours.ceil # Round up to next hour
    hourly_rate = HOURLY_RATES[car_size]
    daily_max = DAILY_MAXIMUMS[car_size]

    total_fee = billable_hours * hourly_rate
    [total_fee, daily_max].min
  end
end

# Main parking garage management system
class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(license_plate, car_size)
    return error_result('Invalid license plate or car size') if invalid_input?(license_plate, car_size)

    parking_result = @garage.admit_car(license_plate, car_size)

    if parking_result.include?('parked at')
      ticket = ParkingTicket.new(license_plate, car_size.downcase)
      @active_tickets[license_plate.to_s] = ticket

      {
        success: true,
        message: parking_result,
        ticket: ticket
      }
    else
      {
        success: false,
        message: parking_result,
        ticket: nil
      }
    end
  end

  def exit_car(license_plate)
    return exit_error_result('Car not found!') unless @active_tickets.key?(license_plate.to_s)

    ticket = @active_tickets[license_plate.to_s]
    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)

    exit_result = @garage.exit_car(license_plate)

    if exit_result.include?('exited')
      @active_tickets.delete(license_plate.to_s)

      {
        success: true,
        message: exit_result,
        fee: fee,
        duration_hours: duration
      }
    else
      exit_error_result(exit_result)
    end
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_cars_parked,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(license_plate)
    @active_tickets[license_plate.to_s]
  end

  private

  def invalid_input?(license_plate, car_size)
    license_plate.nil? || car_size.nil? ||
      license_plate.to_s.strip.empty? ||
      !%w[small medium large].include?(car_size.downcase)
  end

  def error_result(message)
    {
      success: false,
      message: message,
      ticket: nil
    }
  end

  def exit_error_result(message)
    {
      success: false,
      message: message,
      fee: 0.0,
      duration_hours: 0.0
    }
  end

  def total_cars_parked
    @garage.parking_spots.values.sum(&:size)
  end
end
