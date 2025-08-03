require 'securerandom'
require 'time'

class ParkingGarage
  attr_reader :small, :medium, :large

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
    plate = license_plate_no.to_s.strip
    size = normalize_size(car_size)

    return "No space available" if plate.empty? || size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << car
        @small -= 1
        success_message(plate, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        success_message(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        success_message(plate, 'large')
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        success_message(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        success_message(plate, 'large')
      else
        shuffle_medium(car) || "No space available"
      end
    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        success_message(plate, 'large')
      else
        shuffle_large(car) || "No space available"
      end
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s
    small_car  = @parking_spots[:small_spot].find  { |c| c[:plate] == plate }
    medium_car = @parking_spots[:medium_spot].find { |c| c[:plate] == plate }
    large_car  = @parking_spots[:large_spot].find  { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      exit_status(plate)
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      exit_status(plate)
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      exit_status(plate)
    else
      "No space available"
    end
  end

  private

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    return nil unless %w[small medium large].include?(s)
    s
  end

  def shuffle_medium(car)
    # Try to move a small car from medium or large to small spot
    if @small > 0
      victim = @parking_spots[:medium_spot].find { |c| c[:size] == 'small' } ||
               @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
      return nil unless victim

      from = @parking_spots[:medium_spot].include?(victim) ? :medium_spot : :large_spot
      @parking_spots[from].delete(victim)
      @parking_spots[:small_spot] << victim
      @small -= 1

      if from == :medium_spot
        @parking_spots[:medium_spot] << car
        @medium -= 1
        success_message(car[:plate], 'medium')
      else
        @parking_spots[:large_spot] << car
        @large -= 1
        success_message(car[:plate], 'large')
      end
    else
      nil
    end
  end

  def shuffle_large(car)
    # Move a medium car from large to medium if medium available
    if @large > 0
      @parking_spots[:large_spot] << car
      @large -= 1
      return success_message(car[:plate], 'large')
    end

    if @medium > 0
      first_medium = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
      if first_medium
        @parking_spots[:large_spot].delete(first_medium)
        @parking_spots[:medium_spot] << first_medium
        @medium -= 1
        @parking_spots[:large_spot] << car
        @large -= 0 # no change here because we freed and used one
        return success_message(car[:plate], 'large')
      end
    end
    nil
  end

  def success_message(plate, spot_type)
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def exit_status(plate)
    "car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = normalize_size(car_size)
    @entry_time    = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).to_f
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    %w[small medium large].include?(s) ? s : nil
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

  GRACE_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = normalize_size(car_size)
    hours = normalize_hours(duration_hours)
    return 0.0 if size.nil? || hours.nil?

    return 0.0 if hours <= GRACE_HOURS

    billable_hours = (hours - GRACE_HOURS)
    rounded_hours = billable_hours.ceil
    total = rounded_hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end

  private

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    %w[small medium large].include?(s) ? s : nil
  end

  def normalize_hours(h)
    return nil if h.nil?
    num = Float(h) rescue nil
    return nil if num.nil? || num.negative?
    num
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage          = ParkingGarage.new(small, medium, large)
    @fee_calculator  = ParkingFeeCalculator.new
    @tix_in_flight   = {}
  end

  def admit_car(plate, size)
    message = @garage.admit_car(plate, size)
    if message.is_a?(String) && message.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: "No space available" }
    end
  end

  def exit_car(plate)
    key = plate.to_s
    ticket = @tix_in_flight[key]
    return { success: false, message: "No active ticket" } unless ticket

    message = @garage.exit_car(key)
    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    @tix_in_flight.delete(key)
    { success: true, message: message, fee: fee.to_f, duration_hours: duration.to_f }
  end

  def garage_status
    small_available = @garage.small
    medium_available = @garage.medium
    large_available = @garage.large
    total_available = small_available + medium_available + large_available
    total_occupied = @tix_in_flight.size

    {
      small_available: small_available,
      medium_available: medium_available,
      large_available: large_available,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end
end