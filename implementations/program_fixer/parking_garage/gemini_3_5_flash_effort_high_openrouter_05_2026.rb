require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @parked_cars = []
    @assignments = {}
  end

  def admit_car(license_plate_no, car_size)
    normalized_plate = license_plate_no.to_s.strip
    normalized_size = car_size.to_s.strip.downcase

    if normalized_plate.empty? || !['small', 'medium', 'large'].include?(normalized_size)
      return "No space available"
    end

    if @parked_cars.any? { |c| c[:plate] == normalized_plate }
      return "No space available"
    end

    proposed_cars = @parked_cars + [{ plate: normalized_plate, size: normalized_size }]
    new_assignments = assign_spots(proposed_cars)

    if new_assignments
      @parked_cars = proposed_cars
      @assignments = {}
      new_assignments.each do |car, spot|
        @assignments[car[:plate]] = spot
      end
      assigned_spot = @assignments[normalized_plate]
      "car with license plate no. #{normalized_plate} is parked at #{assigned_spot}"
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    normalized_plate = license_plate_no.to_s.strip
    car = @parked_cars.find { |c| c[:plate] == normalized_plate }

    if car
      @parked_cars.delete(car)
      @assignments.delete(normalized_plate)
      # Re-optimize assignments for remaining cars
      new_assignments = assign_spots(@parked_cars)
      if new_assignments
        @assignments = {}
        new_assignments.each do |c, spot|
          @assignments[c[:plate]] = spot
        end
      end
    end

    "car with license plate no. #{normalized_plate} exited"
  end

  def small_available
    @small - @assignments.values.count('small')
  end

  def medium_available
    @medium - @assignments.values.count('medium')
  end

  def large_available
    @large - @assignments.values.count('large')
  end

  def total_occupied
    @parked_cars.size
  end

  def total_available
    small_available + medium_available + large_available
  end

  def parking_spots
    {
      tiny_spot: @parked_cars.select { |c| @assignments[c[:plate]] == 'small' },
      mid_spot: @parked_cars.select { |c| @assignments[c[:plate]] == 'medium' },
      grande_spot: @parked_cars.select { |c| @assignments[c[:plate]] == 'large' }
    }
  end

  def shuffle_medium(kar)
    nil
  end

  def shuffle_large(kar)
    nil
  end

  private

  def assign_spots(cars)
    s_spots = @small
    m_spots = @medium
    l_spots = @large

    larges = cars.select { |c| c[:size] == 'large' }
    mediums = cars.select { |c| c[:size] == 'medium' }
    smalls = cars.select { |c| c[:size] == 'small' }

    return nil if larges.size > l_spots
    l_spots -= larges.size
    larges_assignment = larges.map { |c| [c, 'large'] }

    mediums_assignment = []
    mediums.each do |c|
      if m_spots > 0
        m_spots -= 1
        mediums_assignment << [c, 'medium']
      elsif l_spots > 0
        l_spots -= 1
        mediums_assignment << [c, 'large']
      else
        return nil
      end
    end

    smalls_assignment = []
    smalls.each do |c|
      if s_spots > 0
        s_spots -= 1
        smalls_assignment << [c, 'small']
      elsif m_spots > 0
        m_spots -= 1
        smalls_assignment << [c, 'medium']
      elsif l_spots > 0
        l_spots -= 1
        smalls_assignment << [c, 'large']
      else
        return nil
      end
    end

    (larges_assignment + mediums_assignment + smalls_assignment).to_h
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).to_f
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  def calculate_fee(car_size, duration_hours)
    hours_float = begin
      duration_hours.to_f
    rescue
      0.0
    end

    return 0.0 if hours_float <= 0.25

    size = car_size.to_s.strip.downcase
    unless ['small', 'medium', 'large'].include?(size)
      size = 'small'
    end

    rate = { 'small' => 2.0, 'medium' => 3.0, 'large' => 5.0 }[size]
    max_fee = { 'small' => 20.0, 'medium' => 30.0, 'large' => 50.0 }[size]

    hours = hours_float.ceil
    fee = [hours * rate, max_fee].min
    fee.to_f
  end
end

class ParkingGarageManager
  def initialize(*args)
    if args.size == 1 && args[0].is_a?(Hash)
      h = args[0]
      small_spots = h[:small_spots] || h[:small] || 0
      medium_spots = h[:medium_spots] || h[:medium] || 0
      large_spots = h[:large_spots] || h[:large] || 0
    else
      small_spots = args[0] || 0
      medium_spots = args[1] || 0
      large_spots = args[2] || 0
    end

    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    normalized_plate = plate.to_s.strip
    normalized_size = size.to_s.strip.downcase

    if normalized_plate.empty? || !['small', 'medium', 'large'].include?(normalized_size)
      return {
        success: false,
        ok: false,
        message: "No space available",
        msg: "No space available"
      }
    end

    verdict = @garage.admit_car(normalized_plate, normalized_size)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(normalized_plate, normalized_size)
      @tix_in_flight[normalized_plate] = ticket
      {
        success: true,
        ok: true,
        message: verdict,
        msg: verdict,
        ticket: ticket,
        tix: ticket
      }
    else
      {
        success: false,
        ok: false,
        message: verdict,
        msg: verdict
      }
    end
  end

  def exit_car(plate)
    normalized_plate = plate.to_s.strip
    ticket = @tix_in_flight[normalized_plate]

    unless ticket
      return {
        success: false,
        ok: false,
        message: "Ticket not found",
        msg: "Ticket not found"
      }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    garage_message = @garage.exit_car(normalized_plate)
    @tix_in_flight.delete(normalized_plate)

    {
      success: true,
      ok: true,
      message: garage_message,
      msg: garage_message,
      fee: fee.to_f,
      duration_hours: duration.to_f,
      hours: duration.to_f
    }
  end

  def garage_status
    {
      small_available: @garage.small_available,
      medium_available: @garage.medium_available,
      large_available: @garage.large_available,
      total_occupied: @garage.total_occupied,
      total_available: @garage.total_available,

      small_open: @garage.small_available,
      med_open: @garage.medium_available,
      lrg_open: @garage.large_available,
      spots_left: @garage.total_available,
      ticking: @tix_in_flight.size
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end

  private

  def garage
    @garage
  end
end