require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large  = [large.to_i, 0].max

    @parking_spots = {
      tiny_spot:   [],
      mid_spot:    [],
      grande_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "No space available" if license_plate_no.nil? || license_plate_no.to_s.strip.empty?
    return "No space available" if car_size.nil?
    normalized_size = car_size.to_s.downcase.strip
    return "No space available" unless %w[small medium large].include?(normalized_size)

    kar = { plate: license_plate_no.to_s, size: normalized_size }

    case normalized_size
    when 'small'
      if @small > 0
        @parking_spots[:tiny_spot] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:mid_spot] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end

    when 'large'
      if @large > 0
        @parking_spots[:grande_spot] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    end
  end

  def exit_car(license_plate_no)
    norm_plate = license_plate_no.to_s
    small_car  = @parking_spots[:tiny_spot].detect { |c| c[:plate] == norm_plate }
    medium_car = @parking_spots[:mid_spot].detect   { |c| c[:plate] == norm_plate }
    large_car  = @parking_spots[:grande_spot].detect { |c| c[:plate] == norm_plate }

    if small_car
      @parking_spots[:tiny_spot].delete(small_car)
      @small += 1
      exit_status(norm_plate)
    elsif medium_car
      @parking_spots[:mid_spot].delete(medium_car)
      @medium += 1
      exit_status(norm_plate)
    elsif large_car
      @parking_spots[:grande_spot].delete(large_car)
      @large += 1
      exit_status(norm_plate)
    else
      "car with license plate no. #{norm_plate} not found"
    end
  end

  def shuffle_medium(kar)
    # If a small spot is empty, see if we can move any small car currently in a medium or large spot into a tiny spot
    if @small > 0
      displaced_car = @parking_spots[:mid_spot].find { |c| c[:size] == 'small' }
      if displaced_car
        @parking_spots[:mid_spot].delete(displaced_car)
        @parking_spots[:tiny_spot] << displaced_car
        @small -= 1
        @parking_spots[:mid_spot] << kar
        return parking_status(kar, 'medium')
      end

      displaced_car = @parking_spots[:grande_spot].find { |c| c[:size] == 'small' }
      if displaced_car
        @parking_spots[:grande_spot].delete(displaced_car)
        @parking_spots[:tiny_spot] << displaced_car
        @small -= 1
        @parking_spots[:grande_spot] << kar
        return parking_status(kar, 'large')
      end
    end

    if @large > 0
      displaced_car = @parking_spots[:mid_spot].find { |c| c[:size] == 'small' }
      if displaced_car
        @parking_spots[:mid_spot].delete(displaced_car)
        @parking_spots[:grande_spot] << displaced_car
        @large -= 1
        @parking_spots[:mid_spot] << kar
        return parking_status(kar, 'medium')
      end
    end

    "No space available"
  end

  def shuffle_large(kar)
    displaced_car = @parking_spots[:grande_spot].find { |c| c[:size] == 'medium' }
    if displaced_car && @medium > 0
      @parking_spots[:grande_spot].delete(displaced_car)
      @parking_spots[:mid_spot] << displaced_car
      @medium -= 1
      @parking_spots[:grande_spot] << kar
      return parking_status(kar, 'large')
    end

    displaced_car = @parking_spots[:grande_spot].find { |c| c[:size] == 'small' }
    if displaced_car
      if @small > 0
        @parking_spots[:grande_spot].delete(displaced_car)
        @parking_spots[:tiny_spot] << displaced_car
        @small -= 1
        @parking_spots[:grande_spot] << kar
        return parking_status(kar, 'large')
      elsif @medium > 0
        @parking_spots[:grande_spot].delete(displaced_car)
        @parking_spots[:mid_spot] << displaced_car
        @medium -= 1
        @parking_spots[:grande_spot] << kar
        return parking_status(kar, 'large')
      end
    end

    "No space available"
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : "Ghost car?"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase.strip
    @entry_time    = entry_time
  end

  def duration_hours
    ((Time.now - entry_time) / 3600.0).round(2)
  end

  def valid?
    (Time.now - entry_time) <= 86400 # 24 hours
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
    normalized_size = car_size.to_s.downcase.strip
    duration = duration_hours.to_f
    return 0.0 unless RATES.key?(normalized_size)
    return 0.0 if duration <= 0.25

    hours = duration.ceil
    rate  = RATES[normalized_size]
    total = hours * rate
    [total.to_f, MAX_FEE[normalized_size]].min
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    return { success: false, message: "No space available" } if plate.nil? || plate.to_s.strip.empty?
    return { success: false, message: "No space available" } if size.nil?
    normalized_size = size.to_s.downcase.strip
    return { success: false, message: "No space available" } unless %w[small medium large].include?(normalized_size)

    verdict = @garage.admit_car(plate, normalized_size)

    if verdict.include?('parked')
      ticket = ParkingTicket.new(plate, normalized_size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    norm_plate = plate.to_s
    ticket = @tix_in_flight[norm_plate]
    return { success: false, message: 'Ticket not found' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(norm_plate)

    @tix_in_flight.delete(norm_plate)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    total_occupied = @garage.parking_spots.values.map(&:size).sum
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   total_occupied,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end