require 'securerandom'

class ParkingGarage
  attr_reader :small_total, :medium_total, :large_total
  attr_reader :small_available, :medium_available, :large_available
  attr_reader :parking_spots

  def initialize(small, medium, large)
    @small_total  = [small.to_i, 0].max
    @medium_total = [medium.to_i, 0].max
    @large_total  = [large.to_i, 0].max

    @small_available  = @small_total
    @medium_available = @medium_total
    @large_available  = @large_total

    @parking_spots = {
      small:  [], # stores hashes { plate: 'ABC', size: 'small' }
      medium: [],
      large:  []
    }
  end

  # Accept any plate type, normalize to string. car_size is case-insensitive string.
  # Returns descriptive string on success or informative string on failure.
  def admit_car(license_plate_no, car_size)
    plate = normalize_plate(license_plate_no)
    size = normalize_size(car_size)
    return "Invalid license plate" if plate.nil? || plate.strip.empty?
    return "Invalid car size" if size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small_available > 0
        @parking_spots[:small] << car
        @small_available -= 1
        return "car with license plate no. #{plate} is parked at small"
      elsif @medium_available > 0
        @parking_spots[:medium] << car
        @medium_available -= 1
        return "car with license plate no. #{plate} is parked at medium"
      elsif @large_available > 0
        @parking_spots[:large] << car
        @large_available -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return "No space available"
      end

    when 'medium'
      if @medium_available > 0
        @parking_spots[:medium] << car
        @medium_available -= 1
        return "car with license plate no. #{plate} is parked at medium"
      elsif @large_available > 0
        @parking_spots[:large] << car
        @large_available -= 1
        return "car with license plate no. #{plate} is parked at large"
      elsif @small_available > 0
        # small spots can take medium? No, requirement: medium cannot use small.
        return "No space available"
      else
        return "No space available"
      end

    when 'large'
      if @large_available > 0
        @parking_spots[:large] << car
        @large_available -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        # Attempt simple shuffle: try to find a medium car in medium spot and move it to small (if small available),
        # freeing medium spot for a medium -> then move medium to large? Keep simple: if there's any medium car in medium spot
        # and medium spot exists? Since large needs large spot, we can try to free a large spot by moving a medium currently in large to medium.
        # Find a medium currently occupying a large spot and move it to a medium spot (if available).
        moved = try_shuffle_for_large
        if moved
          @parking_spots[:large] << car
          @large_available -= 1
          return "car with license plate no. #{plate} is parked at large"
        end
        return "No space available"
      end
    else
      return "Invalid car size"
    end
  end

  def exit_car(license_plate_no)
    plate = normalize_plate(license_plate_no)
    return "Invalid license plate" if plate.nil? || plate.strip.empty?

    small_car = @parking_spots[:small].find { |c| c[:plate] == plate }
    if small_car
      @parking_spots[:small].delete(small_car)
      @small_available += 1
      return "car with license plate no. #{plate} exited"
    end

    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate }
    if medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium_available += 1
      return "car with license plate no. #{plate} exited"
    end

    large_car = @parking_spots[:large].find { |c| c[:plate] == plate }
    if large_car
      @parking_spots[:large].delete(large_car)
      @large_available += 1
      return "car with license plate no. #{plate} exited"
    end

    "Car not found"
  end

  def garage_status
    total_available = @small_available + @medium_available + @large_available
    total_occupied = (@small_total + @medium_total + @large_total) - total_available
    {
      small_available: @small_available,
      medium_available: @medium_available,
      large_available: @large_available,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  private

  def normalize_plate(plate)
    return nil if plate.nil?
    plate.to_s
  end

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    return nil unless %w[small medium large].include?(s)
    s
  end

  # Attempt to shuffle cars to free a large spot:
  # If a medium car is occupying a large spot and there is a medium spot available,
  # move that medium car to the medium spot to free up a large spot.
  def try_shuffle_for_large
    # find a medium car currently parked in large spot
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    return false unless medium_in_large
    return false unless @medium_available > 0

    # move it
    @parking_spots[:large].delete(medium_in_large)
    @large_available += 1
    @parking_spots[:medium] << medium_in_large
    @medium_available -= 1
    true
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.nil? ? '' : license_plate.to_s
    @car_size = car_size.nil? ? nil : car_size.to_s.strip.downcase
    @entry_time = entry_time
  end

  # duration in hours as float
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

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil?
    d = duration_hours.to_f
    return 0.0 if d <= 0.0
    return 0.0 if d <= GRACE_PERIOD_HOURS

    size = car_size.to_s.strip.downcase
    rate = RATES[size] || 0.0
    # Round up partial hours to next full hour
    billable_hours = d.ceil
    total = (billable_hours * rate).to_f
    max_fee = MAX_FEE[size] || total
    [total, max_fee].min.to_f
  rescue
    0.0
  end
end

class ParkingGarageManager
  def initialize(small_spots = nil, medium_spots = nil, large_spots = nil)
    # Support both positional arguments and nil defaults
    if small_spots.is_a?(Hash)
      sp = small_spots
      small_spots = sp.fetch(:small, 0)
      medium_spots = sp.fetch(:medium, 0)
      large_spots = sp.fetch(:large, 0)
    end

    small_spots ||= 0
    medium_spots ||= 0
    large_spots ||= 0

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {} # key: plate string -> ParkingTicket
  end

  # Returns hash: { success: bool, message: string, ticket: ParkingTicket (on success) }
  def admit_car(plate, size)
    plate_s = plate.nil? ? '' : plate.to_s
    size_s = size.nil? ? '' : size.to_s

    verdict = @garage.admit_car(plate_s, size_s)
    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate_s, size_s)
      @tix_in_flight[plate_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  # Exit car using license plate. Calculates fee using stored ticket.
  # Returns { success: bool, message: string, fee: float, duration_hours: float }
  def exit_car(plate)
    plate_s = plate.nil? ? '' : plate.to_s
    ticket = @tix_in_flight[plate_s]
    return { success: false, message: 'no active ticket' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_s)
    # remove ticket
    @tix_in_flight.delete(plate_s)

    { success: true, message: result, fee: fee.to_f, duration_hours: duration.to_f }
  end

  def garage_status
    gs = @garage.garage_status
    {
      small_available: gs[:small_available],
      medium_available: gs[:medium_available],
      large_available: gs[:large_available],
      total_occupied: gs[:total_occupied],
      total_available: gs[:total_available]
    }
  end

  def find_ticket(plate)
    return nil if plate.nil?
    @tix_in_flight[plate.to_s]
  end
end