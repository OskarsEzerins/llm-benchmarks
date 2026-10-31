require 'securerandom'

class ParkingGarage
  attr_reader :capacity, :spots

  def initialize(small, medium, large)
    @capacity = {
      small: small.to_i,
      medium: medium.to_i,
      large: large.to_i
    }
    @spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def small
    available_spots(:small)
  end

  def medium
    available_spots(:medium)
  end

  def large
    available_spots(:large)
  end

  def available_spots(type)
    @capacity[type] - @spots[type].size
  end

  def occupied_spots(type)
    @spots[type].size
  end

  def total_available
    @capacity.values.sum - @spots.values.sum(&:size)
  end

  def total_occupied
    @spots.values.sum(&:size)
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.downcase.strip
    return 'No space available' if plate.empty? || !%w[small medium large].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      return park_in(car, :small) if available_spots(:small) > 0
      return park_in(car, :medium) if available_spots(:medium) > 0
      return park_in(car, :large) if available_spots(:large) > 0
      'No space available'
    when 'medium'
      return park_in(car, :medium) if available_spots(:medium) > 0
      return park_in(car, :large) if available_spots(:large) > 0
      try_shuffle_medium(car) || 'No space available'
    when 'large'
      return park_in(car, :large) if available_spots(:large) > 0
      try_shuffle_large(car) || 'No space available'
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    return 'No car found' if plate.empty?

    [:small, :medium, :large].each do |type|
      car = @spots[type].find { |c| c[:plate] == plate }
      next unless car

      @spots[type].delete(car)
      return "car with license plate no. #{plate} exited"
    end

    'No car found'
  end

  private

  def park_in(car, type)
    @spots[type] << car
    "car with license plate no. #{car[:plate]} is parked at #{type}"
  end

  def try_shuffle_medium(car)
    [:medium, :large].each do |target|
      next unless available_spots(target).zero?

      victim = @spots[target].find do |c|
        if c[:size] == 'small'
          available_spots(:small) > 0
        elsif c[:size] == 'medium' && target == :large
          available_spots(:medium) > 0
        else
          false
        end
      end
      next unless victim

      move_to = victim[:size] == 'small' ? :small : :medium
      @spots[target].delete(victim)
      @spots[move_to] << victim
      @spots[target] << car
      return "car with license plate no. #{car[:plate]} is parked at #{target}"
    end

    nil
  end

  def try_shuffle_large(car)
    return nil unless available_spots(:large).zero?

    victim = @spots[:large].find do |c|
      if c[:size] == 'small'
        available_spots(:small) > 0 || available_spots(:medium) > 0
      elsif c[:size] == 'medium'
        available_spots(:medium) > 0
      else
        false
      end
    end
    return nil unless victim

    move_to = if victim[:size] == 'small'
                available_spots(:small) > 0 ? :small : :medium
              else
                :medium
              end

    @spots[:large].delete(victim)
    @spots[move_to] << victim
    @spots[:large] << car
    "car with license plate no. #{car[:plate]} is parked at large"
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = generate_ticket_id
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    duration_hours <= 24.0
  end

  private

  def generate_ticket_id
    SecureRandom.uuid
  end
end

class ParkingFeeCalculator
  RATES = {
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }.freeze

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }.freeze

  GRACE_PERIOD = 0.25

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase.strip
    return 0.0 unless RATES.key?(size)

    duration = begin
      Float(duration_hours)
    rescue StandardError
      return 0.0
    end

    return 0.0 if duration <= GRACE_PERIOD

    chargeable_hours = (duration - GRACE_PERIOD).ceil
    return 0.0 if chargeable_hours <= 0

    total = chargeable_hours * RATES[size]
    [total, MAX_FEE[size]].min.to_f
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
    size_str = size.to_s.downcase.strip

    unless valid_input?(plate_str, size_str)
      return { success: false, message: 'Invalid input', ticket: nil }
    end

    message = @garage.admit_car(plate_str, size_str)

    if message.include?('parked at')
      ticket = ParkingTicket.new(plate_str, size_str)
      @active_tickets[plate_str] = ticket
      { success: true, message: message, ticket: ticket }
    else
      { success: false, message: message, ticket: nil }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip

    if plate_str.empty?
      return { success: false, message: 'Invalid plate', fee: 0.0, duration_hours: 0.0 }
    end

    ticket = @active_tickets[plate_str]

    unless ticket
      return { success: false, message: 'Ticket not found', fee: 0.0, duration_hours: 0.0 }
    end

    result = @garage.exit_car(plate_str)

    if result.include?('exited')
      @active_tickets.delete(plate_str)
      duration = ticket.duration_hours.to_f
      fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
      { success: true, message: result, fee: fee.to_f, duration_hours: duration }
    else
      { success: false, message: result, fee: 0.0, duration_hours: ticket.duration_hours.to_f }
    end
  end

  def garage_status
    {
      small_available: @garage.available_spots(:small),
      medium_available: @garage.available_spots(:medium),
      large_available: @garage.available_spots(:large),
      total_occupied: @garage.total_occupied,
      total_available: @garage.total_available
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s.strip]
  end

  private

  def valid_input?(plate, size)
    !plate.empty? && %w[small medium large].include?(size)
  end
end