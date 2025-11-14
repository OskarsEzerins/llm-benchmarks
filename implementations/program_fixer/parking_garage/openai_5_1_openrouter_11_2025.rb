require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large,
              :total_small, :total_medium, :total_large

  def initialize(small, medium, large)
    @total_small  = [small.to_i, 0].max
    @total_medium = [medium.to_i, 0].max
    @total_large  = [large.to_i, 0].max

    @small  = @total_small
    @medium = @total_medium
    @large  = @total_large

    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  # Returns message string
  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s
    size  = car_size.to_s.strip.downcase

    return "No space available" unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        shuffle_large(car)
      end
    else
      "No space available"
    end
  end

  # Returns message string
  def exit_car(license_plate_no)
    plate = license_plate_no.to_s

    [:small, :medium, :large].each do |spot_type|
      car = @parking_spots[spot_type].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot_type].delete(car)
      case spot_type
      when :small
        @small += 1
      when :medium
        @medium += 1
      when :large
        @large += 1
      end

      return "car with license plate no. #{plate} exited"
    end

    "car with license plate no. #{plate} not found"
  end

  private

  def shuffle_large(car)
    # Try to move a medium car from large to medium, if medium spot available
    candidate_medium = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    moved = false

    if candidate_medium && @medium > 0
      @parking_spots[:large].delete(candidate_medium)
      @parking_spots[:medium] << candidate_medium
      @medium -= 1
      @large += 1
      moved = true
    else
      # Try to move a small car from large to small/medium
      candidate_small = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if candidate_small
        if @small > 0
          @parking_spots[:large].delete(candidate_small)
          @parking_spots[:small] << candidate_small
          @small -= 1
          @large += 1
          moved = true
        elsif @medium > 0
          @parking_spots[:large].delete(candidate_small)
          @parking_spots[:medium] << candidate_small
          @medium -= 1
          @large += 1
          moved = true
        end
      end
    end

    if moved && @large > 0
      @parking_spots[:large] << car
      @large -= 1
      "car with license plate no. #{car[:plate]} is parked at large"
    else
      "No space available"
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.strip.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).to_f
  end

  def valid?
    duration_hours <= 24.0
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

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)
    return 0.0 unless duration_hours.is_a?(Numeric)

    hours = duration_hours.to_f
    return 0.0 if hours <= 0.0
    return 0.0 if hours <= 0.25 # grace period

    billable_hours = (hours - 0.25).ceil
    total = billable_hours * RATES[size]
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
    message = @garage.admit_car(plate, size)

    if message.include?('is parked')
      normalized_size = size.to_s.strip.downcase
      ticket = ParkingTicket.new(plate, normalized_size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message, ticket: nil }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s
    ticket    = @tix_in_flight[plate_str]

    unless ticket
      return {
        success:        false,
        message:        'Ticket not found',
        fee:            0.0,
        duration_hours: 0.0
      }
    end

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    message  = @garage.exit_car(plate_str)

    @tix_in_flight.delete(plate_str)

    {
      success:        true,
      message:        message,
      fee:            fee,
      duration_hours: duration
    }
  end

  def garage_status
    small_available  = @garage.small
    medium_available = @garage.medium
    large_available  = @garage.large

    total_available = small_available + medium_available + large_available
    total_capacity  = @garage.total_small + @garage.total_medium + @garage.total_large
    total_occupied  = total_capacity - total_available

    {
      small_available:  small_available,
      medium_available: medium_available,
      large_available:  large_available,
      total_occupied:   total_occupied,
      total_available:  total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end