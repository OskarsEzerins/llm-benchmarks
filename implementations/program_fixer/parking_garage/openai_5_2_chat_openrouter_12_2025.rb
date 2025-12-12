require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

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
    plate = license_plate_no.to_s.strip
    size  = normalize_size(car_size)
    return "No space available" if plate.empty? || size.nil?

    car = { plate: plate, size: size }

    case size
    when 'small'
      return park(car, 'small')  if @small > 0
      return park(car, 'medium') if @medium > 0
      return park(car, 'large')  if @large > 0
    when 'medium'
      return park(car, 'medium') if @medium > 0
      return park(car, 'large')  if @large > 0
    when 'large'
      return park(car, 'large')  if @large > 0
    end

    "No space available"
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    return "car with license plate no. #{plate} exited" if plate.empty?

    @parking_spots.each do |type, cars|
      car = cars.find { |c| c[:plate] == plate }
      next unless car

      cars.delete(car)
      increment_spot(type)
      return "car with license plate no. #{plate} exited"
    end

    "car with license plate no. #{plate} exited"
  end

  def status
    {
      small_available:  @small,
      medium_available: @medium,
      large_available:  @large,
      total_occupied:  @parking_spots.values.flatten.size,
      total_available: @small + @medium + @large
    }
  end

  private

  def park(car, type)
    @parking_spots[type.to_sym] << car
    decrement_spot(type)
    "car with license plate no. #{car[:plate]} is parked at #{type}"
  end

  def decrement_spot(type)
    case type
    when 'small'  then @small  -= 1
    when 'medium' then @medium -= 1
    when 'large'  then @large  -= 1
    end
  end

  def increment_spot(type)
    case type
    when :small  then @small  += 1
    when :medium then @medium += 1
    when :large  then @large  += 1
    end
  end

  def normalize_size(size)
    return nil if size.nil?
    s = size.to_s.strip.downcase
    %w[small medium large].include?(s) ? s : nil
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
    hours = duration_hours.to_f
    return 0.0 if hours <= 0.25
    return 0.0 unless RATES.key?(size)

    billable_hours = hours.ceil
    total = billable_hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @tickets_active  = {}
  end

  def admit_car(plate, size)
    result = @garage.admit_car(plate, size)
    if result.start_with?('car with license plate')
      ticket = ParkingTicket.new(plate, size)
      @tickets_active[plate.to_s] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    key = plate.to_s
    ticket = @tickets_active[key]
    return { success: false, message: 'Invalid ticket' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    msg = @garage.exit_car(key)
    @tickets_active.delete(key)

    {
      success: true,
      message: msg,
      fee: fee,
      duration_hours: ticket.duration_hours
    }
  end

  def garage_status
    @garage.status
  end

  def find_ticket(plate)
    @tickets_active[plate.to_s]
  end
end