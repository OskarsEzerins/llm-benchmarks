require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large,
              :total_small, :total_medium, :total_large

  def initialize(small, medium, large)
    @total_small  = small.to_i
    @total_medium = medium.to_i
    @total_large  = large.to_i

    @small  = @total_small
    @medium = @total_medium
    @large  = @total_large

    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    return 'Invalid license plate' unless valid_plate?(license_plate_no)

    size = normalize_size(car_size)
    return 'Invalid car size' unless size

    plate = license_plate_no.to_s
    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        'No space available'
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        'No space available'
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s

    [:small, :medium, :large].each do |spot_type|
      car = @parking_spots[spot_type].find { |c| c[:plate] == plate }
      next unless car

      @parking_spots[spot_type].delete(car)
      case spot_type
      when :small  then @small += 1
      when :medium then @medium += 1
      when :large  then @large += 1
      end
      return exit_status(plate)
    end

    "car with license plate no. #{plate} not found"
  end

  def shuffle_large(car)
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }

    if medium_in_large && @medium > 0
      @parking_spots[:large].delete(medium_in_large)
      @parking_spots[:medium] << medium_in_large
      @medium -= 1

      @parking_spots[:large] << car
      parking_status(car, 'large')
    else
      'No space available'
    end
  end

  def parking_status(car, spot_type)
    "car with license plate no. #{car[:plate]} is parked at #{spot_type}"
  end

  def exit_status(plate)
    "car with license plate no. #{plate} exited"
  end

  private

  def valid_plate?(plate)
    return false if plate.nil?
    !plate.to_s.strip.empty?
  end

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.downcase.strip
    %w[small medium large].include?(s) ? s : nil
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = "TK-#{SecureRandom.uuid}"
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase.strip
    @entry_time    = entry_time
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0.0].max
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    @id
  end
end

class ParkingFeeCalculator
  GRACE_PERIOD = 0.25

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
    return 0.0 if car_size.nil?

    size = car_size.to_s.downcase.strip
    rate = RATES[size]
    max_fee = MAX_FEE[size]
    return 0.0 unless rate && max_fee

    return 0.0 if duration_hours.nil?
    return 0.0 unless duration_hours.respond_to?(:to_f)

    duration = duration_hours.to_f
    return 0.0 if duration.respond_to?(:nan?) && duration.nan?
    return 0.0 if duration < 0
    return 0.0 if duration <= GRACE_PERIOD

    billable_hours = (duration - GRACE_PERIOD).ceil
    total = billable_hours * rate

    [total, max_fee].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots = 0, medium_spots = 0, large_spots = 0)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @active_tickets  = {}
  end

  def admit_car(license_plate, car_size)
    return { success: false, message: 'Invalid license plate' } if license_plate.nil?

    plate = license_plate.to_s
    return { success: false, message: 'Invalid license plate' } if plate.strip.empty?

    size = normalize_size(car_size)
    return { success: false, message: 'Invalid car size' } unless size

    result = @garage.admit_car(plate, size)

    if result.is_a?(String) && result.include?('parked')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(license_plate)
    plate = license_plate.nil? ? '' : license_plate.to_s
    ticket = @active_tickets[plate]

    return { success: false, message: "car with license plate no. #{plate} not found" } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate)

    @active_tickets.delete(plate)

    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   total_spots - @garage.small - @garage.medium - @garage.large,
      total_available:  @garage.small + @garage.medium + @garage.large,
      active_tickets:   @active_tickets.size
    }
  end

  def find_ticket(license_plate)
    @active_tickets[license_plate.to_s]
  end

  private

  def garage
    @garage
  end

  def total_spots
    @garage.total_small + @garage.total_medium + @garage.total_large
  end

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.downcase.strip
    %w[small medium large].include?(s) ? s : nil
  end
end