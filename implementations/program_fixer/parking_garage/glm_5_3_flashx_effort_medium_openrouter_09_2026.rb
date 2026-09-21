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
    return 'No space available' unless valid_size?(car_size)
    return 'No space available' unless valid_plate?(license_plate_no)

    plate = license_plate_no.to_s
    size  = car_size.to_s.downcase

    case size
    when 'small'
      if @small > 0
        park(plate, size, :small_spot)
      elsif @medium > 0
        park(plate, size, :medium_spot)
      elsif @large > 0
        park(plate, size, :large_spot)
      else
        'No space available'
      end
    when 'medium'
      if @medium > 0
        park(plate, size, :medium_spot)
      elsif @large > 0
        park(plate, size, :large_spot)
      else
        'No space available'
      end
    when 'large'
      if @large > 0
        park(plate, size, :large_spot)
      elsif shuffle_large
        park(plate, size, :large_spot)
      else
        'No space available'
      end
    end
  end

  def exit_car(license_plate_no)
    return 'No space available' unless valid_plate?(license_plate_no)
    plate = license_plate_no.to_s

    spot_key = @parking_spots.keys.find do |key|
      @parking_spots[key].any? { |c| c[:plate] == plate }
    end

    if spot_key
      car = @parking_spots[spot_key].delete(@parking_spots[spot_key].find { |c| c[:plate] == plate })
      case spot_key
      when :small_spot  then @small  += 1
      when :medium_spot then @medium += 1
      when :large_spot  then @large  += 1
      end
      "car with license plate no. #{plate} exited"
    else
      "car with license plate no. #{plate} not found"
    end
  end

  def occupied_count
    @parking_spots.values.map(&:size).sum
  end

  private

  def valid_size?(size)
    %w[small medium large].include?(size.to_s.downcase)
  end

  def valid_plate?(plate)
    !plate.nil? && !plate.to_s.strip.empty?
  end

  def park(plate, size, spot_key)
    @parking_spots[spot_key] << { plate: plate, size: size }
    case spot_key
    when :small_spot  then @small  -= 1
    when :medium_spot then @medium -= 1
    when :large_spot  then @large  -= 1
    end
    "car with license plate no. #{plate} is parked at #{spot_key.to_s.sub('_spot', '')}"
  end

  # Large car: shuffle a medium car out of a large spot down to a medium spot
  def shuffle_large
    victim = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    return false unless victim && @medium > 0

    @parking_spots[:large_spot].delete(victim)
    @parking_spots[:medium_spot] << victim
    @medium -= 1
    @large += 1
    true
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

  def license_plate_no
    @license_plate
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

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)
    duration = duration_hours.to_f
    return 0.0 if duration < 0

    return 0.0 if duration <= GRACE_PERIOD

    hours = duration.ceil
    total = hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    unless valid_plate?(plate) && valid_size?(size)
      return { success: false, message: 'Invalid license plate or car size' }
    end

    normalized_plate = plate.to_s
    normalized_size  = size.to_s.downcase

    verdict = @garage.admit_car(normalized_plate, normalized_size)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @active_tickets[normalized_plate] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: 'No space available' }
    end
  end

  def exit_car(plate)
    normalized_plate = plate.to_s
    ticket = @active_tickets[normalized_plate]

    unless ticket
      return { success: false, message: "No active ticket for license plate no. #{normalized_plate}" }
    end

    result = @garage.exit_car(normalized_plate)
    unless result.to_s.include?('exited')
      return { success: false, message: result }
    end

    fee    = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    @active_tickets.delete(normalized_plate)

    { success: true, message: "car with license plate no. #{normalized_plate} exited",
      fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    small_avail  = @garage.small
    medium_avail = @garage.medium
    large_avail  = @garage.large
    occupied     = @garage.occupied_count

    {
      small_available:  small_avail,
      medium_available: medium_avail,
      large_available:  large_avail,
      total_occupied:   occupied,
      total_available:  small_avail + medium_avail + large_avail
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s]
  end

  private

  def valid_plate?(plate)
    !plate.nil? && !plate.to_s.strip.empty?
  end

  def valid_size?(size)
    %w[small medium large].include?(size.to_s.downcase)
  end
end