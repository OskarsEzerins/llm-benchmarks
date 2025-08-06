require 'securerandom'

# -----------------------------------------------------------------
# ParkingGarage – manages spots and car placement
# -----------------------------------------------------------------
class ParkingGarage
  attr_reader :available_spots

  SPOT_TYPES = %i[small medium large].freeze

  def initialize(small, medium, large)
    @available_spots = {
      small:   small.to_i,
      medium:  medium.to_i,
      large:   large.to_i
    }

    @spots = {
      small:   [],
      medium:  [],
      large:   []
    }
  end

  # Admit a car, allocate a spot according to size preferences.
  # Returns a hash with :success (bool) and :message (String)
  def admit_car(license_plate_no, car_size)
    plate = license_plate_no&.to_s&.strip
    size  = normalize_size(car_size)

    return { success: false, message: 'Invalid input' } if plate.nil? || plate.empty? || size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      allocate_small(car)
    when 'medium'
      allocate_medium(car)
    when 'large'
      allocate_large(car)
    else
      { success: false, message: 'Invalid car size' }
    end
  end

  # Exit a car, free its spot.
  # Returns a hash with :success (bool) and :message (String)
  def exit_car(license_plate_no)
    plate = license_plate_no&.to_s&.strip
    return { success: false, message: 'Invalid license plate' } if plate.nil? || plate.empty?

    spot, car = locate_car(plate)
    return { success: false, message: "Car with license plate no. #{plate} not found" } unless car

    @spots[spot].delete(car)
    @available_spots[spot] += 1
    { success: true, message: "car with license plate no. #{plate} exited" }
  end

  # -----------------------------------------------------------------
  # Helpers used by manager
  # -----------------------------------------------------------------
  def total_spots
    @available_spots.values.sum
  end

  def total_occupied
    @spots.values.map(&:size).sum
  end

  private

  # -------------------- Allocation helpers ---------------------

  def allocate_small(car)
    if @available_spots[:small] > 0
      park(car, :small)
    elsif @available_spots[:medium] > 0
      park(car, :medium)
    elsif @available_spots[:large] > 0
      park(car, :large)
    else
      { success: false, message: 'No space available' }
    end
  end

  def allocate_medium(car)
    if @available_spots[:medium] > 0
      park(car, :medium)
    elsif @available_spots[:large] > 0
      park(car, :large)
    else
      # try to shuffle a small car from medium to small
      if shuffle_medium(car)
        { success: true, message: "car with license plate no. #{car[:plate]} is parked at medium" }
      else
        { success: false, message: 'No space available' }
      end
    end
  end

  def allocate_large(car)
    if @available_spots[:large] > 0
      park(car, :large)
    else
      # try to shuffle a medium car from large to medium
      if shuffle_large(car)
        { success: true, message: "car with license plate no. #{car[:plate]} is parked at large" }
      else
        { success: false, message: 'No space available' }
      end
    end
  end

  # General parking routine
  def park(car, spot_type)
    @spots[spot_type] << car
    @available_spots[spot_type] -= 1
    { success: true, message: "car with license plate no. #{car[:plate]} is parked at #{spot_type}" }
  end

  # Shuffle a small car occupying a medium spot into a free small spot
  # Returns true if successful, false otherwise.
  def shuffle_medium(new_car)
    victim = @spots[:medium].find { |c| c[:size] == 'small' }
    return false unless victim && @available_spots[:small] > 0

    # Move victim to small spot
    @spots[:medium].delete(victim)
    @available_spots[:medium] += 1
    @spots[:small] << victim
    @available_spots[:small] -= 1

    # Park the incoming medium car
    park(new_car, :medium)
    true
  end

  # Shuffle a medium car occupying a large spot into a free medium spot
  # Returns true if successful, false otherwise.
  def shuffle_large(new_car)
    victim = @spots[:large].find { |c| c[:size] == 'medium' }
    return false unless victim && @available_spots[:medium] > 0

    # Move victim to medium spot
    @spots[:large].delete(victim)
    @available_spots[:large] += 1
    @spots[:medium] << victim
    @available_spots[:medium] -= 1

    # Park the incoming large car
    park(new_car, :large)
    true
  end

  # Locate a car across all spot types.
  def locate_car(plate)
    SPOT_TYPES.each do |type|
      car = @spots[type].find { |c| c[:plate] == plate }
      return [type, car] if car
    end
    [nil, nil]
  end

  # -------------------- Validation helpers ---------------------

  def normalize_size(size)
    return nil unless size
    s = size.to_s.strip.downcase
    %w[small medium large].include?(s) ? s : nil
  end
end

# -----------------------------------------------------------------
# ParkingTicket – represents a ticket for a parked car
# -----------------------------------------------------------------
class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  # Duration in fractional hours (e.g., 2.5 = 2½ hours)
  def duration_hours
    ((Time.now - @entry_time) / 3600.0).round(4)
  end

  # Valid for up to 24 hours after entry
  def valid?
    duration_hours <= 24
  end
end

# -----------------------------------------------------------------
# ParkingFeeCalculator – computes parking fees
# -----------------------------------------------------------------
class ParkingFeeCalculator
  RATES = {
    'small'  => 2.0,
    'medium' => 3.0,
    'large'  => 5.0
  }.freeze

  MAX_DAILY = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  GRACE_PERIOD_HOURS = 0.25 # first 15 minutes free

  # Returns a Float fee. Returns 0.0 for negative or within grace period.
  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size) && duration_hours && duration_hours >= 0

    payable = duration_hours - GRACE_PERIOD_HOURS
    return 0.0 if payable <= 0

    hours = payable.ceil
    fee = hours * RATES[size]
    [fee, MAX_DAILY[size]].min.to_f
  end
end

# -----------------------------------------------------------------
# ParkingGarageManager – high‑level API for the garage system
# -----------------------------------------------------------------
class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @tickets_in_flight = {}
  end

  # Admit a car; on success a ticket is created.
  # Returns a hash with :success, :message, and optionally :ticket.
  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)

    if result[:success]
      ticket = ParkingTicket.new(plate, size)
      @tickets_in_flight[plate.to_s] = ticket
      { success: true, message: result[:message], ticket: ticket }
    else
      { success: false, message: result[:message] }
    end
  end

  # Exit a car, calculate fee, and clear the ticket.
  # Returns a hash with :success, :message, :fee, :duration_hours.
  def exit_car(plate)
    ticket = @tickets_in_flight[plate.to_s]
    return { success: false, message: 'Ticket not found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    exit_result = @garage.exit_car(plate)

    @tickets_in_flight.delete(plate.to_s)
    {
      success: exit_result[:success],
      message: exit_result[:message],
      fee: fee,
      duration_hours: ticket.duration_hours.round(2)
    }
  end

  # Current garage status.
  # Returns a hash with spot availability and occupancy numbers.
  def garage_status
    {
      small_available:   @garage.available_spots[:small],
      medium_available:  @garage.available_spots[:medium],
      large_available:   @garage.available_spots[:large],
      total_occupied:    @garage.total_occupied,
      total_available:   @garage.total_spots,
      tickets_active:    @tickets_in_flight.size
    }
  end

  # Retrieve a ticket by license plate (or nil if not present).
  def find_ticket(plate)
    @tickets_in_flight[plate.to_s]
  end
end