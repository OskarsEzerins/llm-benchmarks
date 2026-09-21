require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small_spot:  [],
      medium_spot: [],
      large_spot:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    return 'No space available' if license_plate_no.nil?
    plate = license_plate_no.to_s.strip
    return 'No space available' if plate.empty?

    size = car_size.to_s.downcase.strip
    kar  = { plate: plate, size: size }

    case size
    when 'small'
      if @small.positive?
        @parking_spots[:small_spot] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium.positive?
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large.positive?
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        'No space available'
      end
    when 'medium'
      if @medium.positive?
        @parking_spots[:medium_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large.positive?
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        'No space available'
      end
    when 'large'
      if @large.positive?
        @parking_spots[:large_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      elsif shuffle_large(kar)
        parking_status(kar, 'large')
      else
        'No space available'
      end
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    return 'No space available' if license_plate_no.nil?
    plate = license_plate_no.to_s.strip

    if (small_car = @parking_spots[:small_spot].detect { |c| c[:plate] == plate })
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      exit_status(plate)
    elsif (medium_car = @parking_spots[:medium_spot].detect { |c| c[:plate] == plate })
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      exit_status(plate)
    elsif (large_car = @parking_spots[:large_spot].detect { |c| c[:plate] == plate })
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      exit_status(plate)
    else
      exit_status
    end
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    return false unless first_medium

    @parking_spots[:large_spot].delete(first_medium)
    @parking_spots[:medium_spot] << first_medium
    @medium -= 1
    true
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : 'No space available'
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(2)
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
  }

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    duration = begin
      Float(duration_hours)
    rescue ArgumentError, TypeError
      return 0.0
    end
    return 0.0 if duration.nan? || duration < 0
    return 0.0 if duration <= 0.25

    hours = duration.ceil
    total = hours * RATES[size]
    [total.to_f, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    return { success: false, message: 'Invalid input' } if plate.nil? || size.nil?
    plate = plate.to_s.strip
    size  = size.to_s.downcase.strip
    return { success: false, message: 'Invalid input' } if plate.empty?

    verdict = @garage.admit_car(plate, size)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    return { success: false, message: 'No active ticket' } if plate.nil?
    plate = plate.to_s.strip
    ticket = @tix_in_flight[plate]
    return { success: false, message: 'No active ticket' } unless ticket

    fee    = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = begin
      @garage.exit_car(plate)
    rescue StandardError
      'error'
    end

    @tix_in_flight.delete(plate)
    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    total_occupied = @garage.parking_spots.values.map(&:size).sum
    small_available = @garage.small
    medium_available = @garage.medium
    large_available = @garage.large
    total_available = small_available + medium_available + large_available
    {
      small_available:  small_available,
      medium_available: medium_available,
      large_available:  large_available,
      total_occupied:   total_occupied,
      total_available:  total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end
end