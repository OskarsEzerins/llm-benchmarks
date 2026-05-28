require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      tiny_spot:   [],
      mid_spot:    [],
      grande_spot: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return parking_status if license_plate_no.nil?

    plate = license_plate_no.to_s
    return parking_status if plate.strip.empty?

    return parking_status if car_size.nil?

    size = car_size.to_s.downcase
    return parking_status unless %w[small medium large].include?(size)

    kar = { plate: plate, size: size }

    case size
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
        parking_status
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
    return exit_status if license_plate_no.nil?

    plate = license_plate_no.to_s

    small_car  = @parking_spots[:tiny_spot].detect   { |c| c[:plate] == plate }
    medium_car = @parking_spots[:mid_spot].find      { |c| c[:plate] == plate }
    large_car  = @parking_spots[:grande_spot].find   { |c| c[:plate] == plate }

    if small_car
      @parking_spots[:tiny_spot].delete(small_car)
      @small += 1
      exit_status(plate)
    elsif medium_car
      @parking_spots[:mid_spot].delete(medium_car)
      @medium += 1
      exit_status(plate)
    elsif large_car
      @parking_spots[:grande_spot].delete(large_car)
      @large += 1
      exit_status(plate)
    else
      exit_status
    end
  end

  def shuffle_medium(kar)
    victim = (@parking_spots[:mid_spot] + @parking_spots[:grande_spot]).first
    return parking_status unless victim

    where = @parking_spots.key(victim) || :mid_spot

    if @small > 0
      @parking_spots[where].delete(victim)
      @parking_spots[:tiny_spot] << victim
      @small -= 1
      @parking_spots[where] << kar
      parking_status(kar, where.to_s.sub('_spot', '').sub('tiny', 'small').sub('mid', 'medium').sub('grande', 'large'))
    else
      parking_status
    end
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:grande_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:grande_spot].delete(first_medium)
      @parking_spots[:mid_spot] << first_medium
      @medium -= 1
      @parking_spots[:grande_spot] << kar
      parking_status(kar, 'large')
    else
      parking_status
    end
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      'No space available'
    end
  end

  def exit_status(plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      'No space available'
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{SecureRandom.uuid}"
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
    return 0.0 if car_size.nil? || duration_hours.nil?

    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)

    dur = duration_hours.to_f
    return 0.0 if dur < 0
    return 0.0 if dur <= GRACE_PERIOD

    hours = dur.ceil
    rate  = RATES[size]
    total = hours * rate
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
    verdict = @garage.admit_car(plate, size)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate.to_s] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    key = plate.to_s
    ticket = @tix_in_flight[key]
    return { success: false, message: 'No active ticket found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate)

    duration = ticket.duration_hours
    @tix_in_flight.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @tix_in_flight.size,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tix_in_flight.fetch(plate.to_s, nil)
  end
end