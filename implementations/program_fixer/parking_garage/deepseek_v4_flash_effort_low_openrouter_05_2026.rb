require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large, :parking_spots

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size  = car_size.to_s.downcase

    return 'Invalid license plate' if plate.empty?
    return 'Invalid car size' unless %w[small medium large].include?(size)

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << { plate: plate, size: size }
        @small -= 1
        parking_status(plate, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << { plate: plate, size: size }
        @medium -= 1
        parking_status(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large] << { plate: plate, size: size }
        @large -= 1
        parking_status(plate, 'large')
      else
        'No space available'
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << { plate: plate, size: size }
        @medium -= 1
        parking_status(plate, 'medium')
      elsif @large > 0
        @parking_spots[:large] << { plate: plate, size: size }
        @large -= 1
        parking_status(plate, 'large')
      else
        'No space available'
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << { plate: plate, size: size }
        @large -= 1
        parking_status(plate, 'large')
      else
        shuffle_large(plate, size)
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    return 'No car found with that plate' if plate.empty?

    # Search all spot arrays
    spot_type = nil
    car = nil

    %i[small medium large].each do |type|
      found = @parking_spots[type].find { |c| c[:plate] == plate }
      if found
        spot_type = type
        car = found
        break
      end
    end

    return 'No car found with that plate' unless car

    # Remove car and free spot
    @parking_spots[spot_type].delete(car)
    case spot_type
    when :small then @small += 1
    when :medium then @medium += 1
    when :large then @large += 1
    end

    exit_status(plate)
  end

  private

  def shuffle_large(plate, size)
    # Find a medium car currently in a large spot
    medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    return 'No space available' unless medium_in_large && @medium > 0

    # Move the medium car from large to medium
    @parking_spots[:large].delete(medium_in_large)
    @parking_spots[:medium] << medium_in_large
    @large += 1   # free one large spot
    @medium -= 1  # occupy one medium spot

    # Park the large car in the freed large spot
    @parking_spots[:large] << { plate: plate, size: size }
    @large -= 1

    parking_status(plate, 'large')
  end

  def parking_status(plate, spot_type)
    "car with license plate no. #{plate} is parked at #{spot_type}"
  end

  def exit_status(plate)
    "car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24
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
    return 0.0 unless RATES.key?(size)

    dur = duration_hours.to_f
    return 0.0 if dur <= 0

    # Grace period: first 15 minutes (0.25 hours) free
    billable = [dur - 0.25, 0.0].max
    return 0.0 if billable <= 0

    hours = billable.ceil
    fee = hours * RATES[size]
    [fee, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str  = size.to_s.downcase

    return { success: false, message: 'Invalid license plate', ticket: nil } if plate_str.empty?
    return { success: false, message: 'Invalid car size', ticket: nil } unless %w[small medium large].include?(size_str)

    result = @garage.admit_car(plate_str, size_str)

    if result.start_with?('car with license plate no.')
      ticket = ParkingTicket.new(plate_str, size_str)
      @active_tickets[plate_str] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result, ticket: nil }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @active_tickets[plate_str]
    return { success: false, message: 'No active ticket for this car', fee: nil, duration_hours: nil } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    exit_result = @garage.exit_car(plate_str)

    @active_tickets.delete(plate_str)

    if exit_result.start_with?('car with license plate no.')
      { success: true, message: exit_result, fee: fee, duration_hours: ticket.duration_hours }
    else
      { success: false, message: exit_result, fee: nil, duration_hours: nil }
    end
  end

  def garage_status
    small_avail = @garage.small
    medium_avail = @garage.medium
    large_avail = @garage.large
    total_available = small_avail + medium_avail + large_avail
    total_spots = @garage.small + @garage.medium + @garage.large + total_occupied_from_counts
    total_occupied = total_spots - total_available

    {
      small_available: small_avail,
      medium_available: medium_avail,
      large_available: large_avail,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end

  private

  def total_occupied_from_counts
    # Since we only track available spots, we need to compute original total spots
    # Actually we stored counts separately; we can sum occupied by counting cars in spots
    @garage.parking_spots.values.map(&:size).sum
  end
end