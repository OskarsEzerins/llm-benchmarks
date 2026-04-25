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
    kar = { plate: license_plate_no.to_s, size: car_size.to_s.downcase }

    case car_size.to_s.downcase
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
        'No space available'
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
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate_str = license_plate_no.to_s
    small_car  = @parking_spots[:tiny_spot].find { |c| c[:plate] == plate_str }
    medium_car = @parking_spots[:mid_spot].find   { |c| c[:plate] == plate_str }
    large_car  = @parking_spots[:grande_spot].find { |c| c[:plate] == plate_str }

    if small_car
      @parking_spots[:tiny_spot].delete(small_car)
      @small += 1
      exit_status(plate_str)
    elsif medium_car
      @parking_spots[:mid_spot].delete(medium_car)
      @medium += 1
      exit_status(plate_str)
    elsif large_car
      @parking_spots[:grande_spot].delete(large_car)
      @large += 1
      exit_status(plate_str)
    else
      'No car found'
    end
  end

  def shuffle_medium(kar)
    if @small > 0
      victim = (@parking_spots[:mid_spot] + @parking_spots[:grande_spot]).sample
      return 'No space available' unless victim

      @parking_spots.each do |key, spots|
        if spots.include?(victim)
          @parking_spots[key].delete(victim)
          victim_size = key == :mid_spot ? :medium : :large
          decrement_count(victim_size)
          break
        end
      end
      
      @parking_spots[:tiny_spot] << victim
      @small -= 1
      
      case kar[:size]
      when 'medium'
        @parking_spots[:mid_spot] << kar
        @medium += 1
        parking_status(kar, 'medium')
      when 'large'
        @parking_spots[:grande_spot] << kar
        @large += 1
        parking_status(kar, 'large')
      else
        'No space available'
      end
    else
      'No space available'
    end
  end

  def shuffle_large(kar)
    first_medium = @parking_spots[:grande_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:grande_spot].delete(first_medium)
      @parking_spots[:mid_spot] << first_medium
      @medium -= 1
      @parking_spots[:grande_spot] << kar
      @large += 1
      @large -= 1
      parking_status(kar, 'large')
    else
      'No space available'
    end
  end

  def decrement_count(size)
    case size
    when :small
      @small -= 1
    when :medium
      @medium -= 1
    when :large
      @large -= 1
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
      'No car found'
    end
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
    ((Time.now - @entry_time) / 3600.0).round(1)
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    "TK-#{rand(9999)}"
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
    return 0.0 if duration_hours.nil? || !duration_hours.is_a?(Numeric) || duration_hours < 0
    return 0.0 if duration_hours <= 0.25
    
    size = car_size.to_s.downcase
    return 0.0 unless ['small', 'medium', 'large'].include?(size)
    
    hours = duration_hours.ceil
    rate  = RATES[size] || 0.0
    total = hours * rate
    max = MAX_FEE[size] || 999.0
    [total, max].min.to_f
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    return { success: false, message: 'No space available' } if plate.nil? || plate.to_s.strip.empty?
    return { success: false, message: 'No space available' } if size.nil? || size.to_s.strip.empty?
    
    verdict = @garage.admit_car(plate, size)

    if verdict.include?('is parked at')
      ticket = ParkingTicket.new(plate, size)
      plate_key = plate.to_s
      @tix_in_flight[plate_key] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_key = plate.to_s
    ticket = @tix_in_flight[plate_key]
    return { success: false, message: 'No active ticket found' } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_key)

    @tix_in_flight.delete(plate_key)
    { success: true, message: result, fee: fee.to_f, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: count_occupied,
      total_available: @garage.small + @garage.medium + @garage.large,
      active_tickets: @tix_in_flight.size
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s]
  end

  private

  def count_occupied
    @garage.parking_spots.values.map(&:size).sum
  end

  def garage
    @garage
  end
end