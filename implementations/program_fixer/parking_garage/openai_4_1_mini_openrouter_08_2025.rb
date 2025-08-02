require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    return "No space available" if license_plate_no.nil? || license_plate_no.to_s.strip.empty?
    return "No space available" unless %w[small medium large].include?(car_size.downcase)

    car_size = car_size.downcase
    kar = { plate: license_plate_no.to_s, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar) || "No space available"
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar) || "No space available"
      end
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate_str = license_plate_no.to_s
    small_car  = @parking_spots[:small].detect { |c| c[:plate] == plate_str }
    medium_car = @parking_spots[:medium].detect { |c| c[:plate] == plate_str }
    large_car  = @parking_spots[:large].detect { |c| c[:plate] == plate_str }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      exit_status(plate_str)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      exit_status(plate_str)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      exit_status(plate_str)
    else
      exit_status
    end
  end

  def shuffle_medium(kar)
    victim = (@parking_spots[:medium] + @parking_spots[:large]).sample
    return nil unless victim

    where = @parking_spots.key(victim) || :medium
    @parking_spots[where].delete(victim)

    if @small > 0
      @parking_spots[:small] << victim
      @small -= 1
      @medium += 1 if where == :medium
      @large += 1  if where == :large
    else
      # Can't shuffle if no small spots available
      # Put victim back and return nil
      @parking_spots[where] << victim
      return nil
    end

    @parking_spots[where] << kar
    case where
    when :medium then @medium -= 1
    when :large then @large -= 1
    end
    parking_status(kar, where.to_s)
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    return nil unless first_medium
    return nil if @medium <= 0

    @parking_spots[:large].delete(first_medium)
    @parking_spots[:medium] << first_medium
    @medium -= 1
    @large += 1

    @parking_spots[:large] << kar
    @large -= 1
    parking_status(kar, 'large')
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : "Car not found"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size      = car_size.downcase
    @entry_time    = entry_time + rand(60)
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.to_f).round(2)
  end

  def valid?
    duration_hours <= 24
  end

  private

  def generate_ticket_id
    "TK-#{rand(9999).to_s.rjust(4, '0')}"
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

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= 0
    return 0.0 if duration_hours <= GRACE_PERIOD_HOURS

    car_size = car_size.downcase
    rate = RATES[car_size] || 5.0

    # Subtract grace period
    billable_hours = (duration_hours - GRACE_PERIOD_HOURS).ceil
    total = billable_hours * rate
    max_fee = MAX_FEE[car_size] || 999.0

    [[total, 0.0].max, max_fee].min.to_f
  rescue
    0.0
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @tix_in_flight   = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str = size.to_s.downcase.strip
    unless valid_plate?(plate_str) && valid_size?(size_str)
      return { success: false, message: "Invalid input", ticket: nil }
    end

    verdict = @garage.admit_car(plate_str, size_str)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict, ticket: nil }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tix_in_flight[plate_str]
    return { success: false, message: 'No active ticket found', fee: 0.0, duration_hours: 0.0 } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)

    @tix_in_flight.delete(plate_str)
    { success: true, message: result, fee: fee.to_f, duration_hours: ticket.duration_hours }
  rescue StandardError
    { success: false, message: 'Error processing exit', fee: 0.0, duration_hours: 0.0 }
  end

  def garage_status
    small_avail  = @garage.small
    medium_avail = @garage.medium
    large_avail  = @garage.large
    total_occupied = (initial_small - small_avail) + (initial_medium - medium_avail) + (initial_large - large_avail)
    total_available = small_avail + medium_avail + large_avail

    {
      small_available: small_avail,
      medium_available: medium_avail,
      large_available: large_avail,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end

  private

  def garage
    @garage
  end

  def valid_plate?(plate)
    !plate.nil? && !plate.strip.empty?
  end

  def valid_size?(size)
    %w[small medium large].include?(size)
  end

  def initial_small
    @initial_small ||= @garage.small + @garage.parking_spots[:small].size
  end

  def initial_medium
    @initial_medium ||= @garage.medium + @garage.parking_spots[:medium].size
  end

  def initial_large
    @initial_large ||= @garage.large + @garage.parking_spots[:large].size
  end
end