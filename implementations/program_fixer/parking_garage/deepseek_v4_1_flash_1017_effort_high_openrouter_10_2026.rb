require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = normalize_count(small)
    @medium = normalize_count(medium)
    @large = normalize_count(large)
    @parking_spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    return "No space available" if plate.empty?

    size = car_size.to_s.downcase
    return "No space available" unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
        return parked_message(plate, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return parked_message(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return parked_message(plate, 'large')
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
        return parked_message(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return parked_message(plate, 'large')
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
        return parked_message(plate, 'large')
      else
        shuffled = shuffle_for_large(plate)
        return shuffled if shuffled
      end
    end

    "No space available"
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    return "car with license plate no. #{plate} not found" if plate.empty?

    @parking_spots.each do |spot_type, cars|
      car = cars.find { |c| c[:plate] == plate }
      next unless car

      cars.delete(car)
      case spot_type
      when :small
        @small += 1
      when :medium
        @medium += 1
      when :large
        @large += 1
      end
      return "car with license plate no. #{plate} exited"
    end

    "car with license plate no. #{plate} not found"
  end

  private

  def normalize_count(value)
    count = (value || 0).to_i
    count.negative? ? 0 : count
  end

  def parked_message(plate, spot_type)
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def shuffle_for_large(plate)
    candidate = @parking_spots[:large].find { |c| c[:size] == 'medium' && @medium > 0 }
    candidate ||= @parking_spots[:large].find do |c|
      c[:size] == 'small' && (@small > 0 || @medium > 0)
    end

    return nil unless candidate

    @parking_spots[:large].delete(candidate)

    if candidate[:size] == 'medium'
      @parking_spots[:medium] << candidate
      @medium -= 1
    else
      if @small > 0
        @parking_spots[:small] << candidate
        @small -= 1
      else
        @parking_spots[:medium] << candidate
        @medium -= 1
      end
    end

    @parking_spots[:large] << { plate: plate, size: 'large' }
    parked_message(plate, 'large')
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate, :license_plate_no

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s.strip
    @license_plate_no = @license_plate
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time || Time.now
  end

  def duration_hours
    seconds = Time.now - @entry_time
    hours = seconds / 3600.0
    hours.negative? ? 0.0 : hours
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

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)

    begin
      duration = Float(duration_hours)
    rescue ArgumentError, TypeError
      return 0.0
    end

    return 0.0 unless duration.finite?
    return 0.0 if duration.negative?
    return 0.0 if duration <= 0.25

    hours = duration.ceil
    total = hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots = 0, medium_spots = 0, large_spots = 0, **options)
    if small_spots.is_a?(Hash)
      hash = small_spots
      small_spots = hash[:small_spots] || hash[:small] || 0
      medium_spots = hash[:medium_spots] || hash[:medium] || 0
      large_spots = hash[:large_spots] || hash[:large] || 0
    end

    if options.any?
      small_spots = options[:small_spots] || options[:small] || small_spots
      medium_spots = options[:medium_spots] || options[:medium] || medium_spots
      large_spots = options[:large_spots] || options[:large] || large_spots
    end

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    plate_key = plate.to_s.strip

    if !plate_key.empty? && @tix_in_flight.key?(plate_key)
      return {
        success: false,
        message: "car with license plate no. #{plate_key} is already parked"
      }
    end

    message = @garage.admit_car(plate, size)

    if message.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      @tix_in_flight[plate_key] = ticket
      {
        success: true,
        message: message,
        ticket: ticket
      }
    else
      {
        success: false,
        message: message
      }
    end
  end

  def exit_car(plate)
    plate_key = plate.to_s.strip
    ticket = @tix_in_flight[plate_key]

    unless ticket
      return {
        success: false,
        message: "car with license plate no. #{plate_key} not found"
      }
    end

    duration_hours = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration_hours)
    result = @garage.exit_car(plate_key)

    if result.include?('exited')
      @tix_in_flight.delete(plate_key)
      {
        success: true,
        message: result,
        fee: fee,
        duration_hours: duration_hours
      }
    else
      {
        success: false,
        message: result
      }
    end
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @garage.parking_spots.values.map { |cars| cars.size }.sum,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end
end