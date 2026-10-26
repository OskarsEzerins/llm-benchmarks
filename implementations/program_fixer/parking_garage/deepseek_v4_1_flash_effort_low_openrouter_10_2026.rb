require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = [small.to_i, 0].max
    @medium = [medium.to_i, 0].max
    @large  = [large.to_i, 0].max

    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s
    return "No space available" if plate.strip.empty?

    size = car_size.to_s.downcase
    return "No space available" unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      spot = nil
      if @small > 0
        spot = :small
      elsif @medium > 0
        spot = :medium
      elsif @large > 0
        spot = :large
      end

      if spot
        park_car(car, spot)
        return parked_message(plate, spot)
      end

    when 'medium'
      if @medium > 0
        park_car(car, :medium)
        return parked_message(plate, :medium)
      elsif @large > 0
        park_car(car, :large)
        return parked_message(plate, :large)
      else
        spot = try_shuffle_for_medium(car)
        return parked_message(plate, spot) if spot
      end

    when 'large'
      if @large > 0
        park_car(car, :large)
        return parked_message(plate, :large)
      else
        spot = try_shuffle_for_large(car)
        return parked_message(plate, spot) if spot
      end
    end

    "No space available"
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s

    @parking_spots.each do |spot, cars|
      car = cars.find { |c| c[:plate] == plate }
      next unless car

      cars.delete(car)
      increment_spot(spot)
      return "car with license plate no. #{plate} exited"
    end

    "car with license plate no. #{plate} not found"
  end

  private

  def parked_message(plate, spot)
    "car with license plate no. #{plate} is parked at #{spot}"
  end

  def park_car(car, spot)
    @parking_spots[spot] << car
    decrement_spot(spot)
  end

  def move_car(car, from, to)
    @parking_spots[from].delete(car)
    @parking_spots[to] << car
    increment_spot(from)
    decrement_spot(to)
  end

  def increment_spot(spot)
    case spot
    when :small  then @small += 1
    when :medium then @medium += 1
    when :large  then @large += 1
    end
  end

  def decrement_spot(spot)
    case spot
    when :small  then @small -= 1
    when :medium then @medium -= 1
    when :large  then @large -= 1
    end
  end

  def try_shuffle_for_medium(car)
    if @small > 0
      small_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if small_in_medium
        move_car(small_in_medium, :medium, :small)
        park_car(car, :medium)
        return :medium
      end
    end

    if @small > 0
      small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_in_large
        move_car(small_in_large, :large, :small)
        park_car(car, :large)
        return :large
      end
    end

    if @medium > 0
      small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_in_large
        move_car(small_in_large, :large, :medium)
        park_car(car, :large)
        return :large
      end
    end

    if @medium > 0
      medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      if medium_in_large
        move_car(medium_in_large, :large, :medium)
        park_car(car, :large)
        return :large
      end
    end

    if @small > 0
      small_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if small_in_medium
        medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
        if medium_in_large
          move_car(small_in_medium, :medium, :small)
          move_car(medium_in_large, :large, :medium)
          park_car(car, :large)
          return :large
        end

        small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
        if small_in_large
          move_car(small_in_medium, :medium, :small)
          move_car(small_in_large, :large, :medium)
          park_car(car, :large)
          return :large
        end
      end
    end

    nil
  end

  def try_shuffle_for_large(car)
    if @medium > 0
      medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
      if medium_in_large
        move_car(medium_in_large, :large, :medium)
        park_car(car, :large)
        return :large
      end
    end

    if @small > 0
      small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_in_large
        move_car(small_in_large, :large, :small)
        park_car(car, :large)
        return :large
      end
    end

    if @medium > 0
      small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }
      if small_in_large
        move_car(small_in_large, :large, :medium)
        park_car(car, :large)
        return :large
      end
    end

    if @small > 0
      small_in_medium = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if small_in_medium
        medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
        small_in_large = @parking_spots[:large].find { |c| c[:size] == 'small' }

        if medium_in_large || small_in_large
          move_car(small_in_medium, :medium, :small)
          if medium_in_large
            move_car(medium_in_large, :large, :medium)
          else
            move_car(small_in_large, :large, :medium)
          end
          park_car(car, :large)
          return :large
        end
      end
    end

    nil
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id            = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size      = car_size.to_s.downcase
    @entry_time    = entry_time || Time.now
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

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)

    begin
      duration = Float(duration_hours)
    rescue ArgumentError, TypeError
      return 0.0
    end

    return 0.0 if duration < 0
    return 0.0 if duration <= 0.25

    hours = duration.ceil
    total = hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots = 0, medium_spots = 0, large_spots = 0, **options)
    if options.any?
      small_spots  = options[:small_spots]  if options.key?(:small_spots)
      medium_spots = options[:medium_spots] if options.key?(:medium_spots)
      large_spots  = options[:large_spots]  if options.key?(:large_spots)
    end

    @garage          = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator  = ParkingFeeCalculator.new
    @active_tickets  = {}
  end

  def admit_car(plate, size)
    plate_key = plate.to_s

    if @active_tickets.key?(plate_key)
      return { success: false, message: "car with license plate no. #{plate_key} is already parked" }
    end

    result = @garage.admit_car(plate, size)

    if result.start_with?("car with license plate no.") && result.include?("is parked at")
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate_key] = ticket
      { success: true, message: result, ticket: ticket }
    else
      { success: false, message: result }
    end
  end

  def exit_car(plate)
    plate_key = plate.to_s
    ticket = @active_tickets[plate_key]

    return { success: false, message: "No active ticket for license plate no. #{plate_key}" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_key)

    if result.include?("exited")
      @active_tickets.delete(plate_key)
      { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
    else
      { success: false, message: result }
    end
  end

  def garage_status
    total_occupied = @garage.parking_spots.values.sum(&:size)
    total_available = @garage.small + @garage.medium + @garage.large

    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s]
  end
end