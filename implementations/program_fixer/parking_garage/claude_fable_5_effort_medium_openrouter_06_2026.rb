require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  VALID_SIZES = %w[small medium large].freeze

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
    size  = car_size.to_s.strip.downcase

    return parking_status if plate.empty? || !VALID_SIZES.include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_medium(car)
      end
    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip

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
      exit_status
    end
  end

  private

  def shuffle_medium(car)
    return parking_status unless @small > 0

    %i[medium_spot large_spot].each do |spot_key|
      victim = @parking_spots[spot_key].find { |c| c[:size] == 'small' }
      next unless victim

      @parking_spots[spot_key].delete(victim)
      @parking_spots[:small_spot] << victim
      @small -= 1
      @parking_spots[spot_key] << car
      return parking_status(car, spot_key.to_s.sub('_spot', ''))
    end

    parking_status
  end

  def shuffle_large(car)
    medium_victim = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if medium_victim && @medium > 0
      @parking_spots[:large_spot].delete(medium_victim)
      @parking_spots[:medium_spot] << medium_victim
      @medium -= 1
      @parking_spots[:large_spot] << car
      return parking_status(car, 'large')
    end

    small_victim = @parking_spots[:large_spot].find { |c| c[:size] == 'small' }
    if small_victim
      if @small > 0
        @parking_spots[:large_spot].delete(small_victim)
        @parking_spots[:small_spot] << small_victim
        @small -= 1
        @parking_spots[:large_spot] << car
        return parking_status(car, 'large')
      elsif @medium > 0
        @parking_spots[:large_spot].delete(small_victim)
        @parking_spots[:medium_spot] << small_victim
        @medium -= 1
        @parking_spots[:large_spot] << car
        return parking_status(car, 'large')
      end
    end

    parking_status
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
      'No car found'
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.strip.downcase
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
  }.freeze

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }.freeze

  GRACE_PERIOD_HOURS = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    return 0.0 unless RATES.key?(size)

    hours = begin
      Float(duration_hours)
    rescue StandardError, TypeError, ArgumentError
      return 0.0
    end

    return 0.0 if hours <= 0 || hours <= GRACE_PERIOD_HOURS

    billable_hours = hours.ceil
    total = billable_hours * RATES[size]
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
    message = @garage.admit_car(plate, size)

    if message.to_s.include?('parked')
      key    = plate.to_s.strip
      ticket = ParkingTicket.new(key, size)
      @active_tickets[key] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message.to_s }
    end
  end

  def exit_car(plate)
    key    = plate.to_s.strip
    ticket = @active_tickets[key]
    return { success: false, message: 'No active ticket found' } unless ticket

    duration = ticket.duration_hours
    fee      = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result   = @garage.exit_car(key)

    @active_tickets.delete(key)
    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @active_tickets.size,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end
end