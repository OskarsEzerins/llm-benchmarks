require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small_capacity  = small.to_i
    @medium_capacity = medium.to_i
    @large_capacity  = large.to_i

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
    update_counts
  end

  def small
    @small_capacity - @parking_spots[:small].size
  end

  def medium
    @medium_capacity - @parking_spots[:medium].size
  end

  def large
    @large_capacity - @parking_spots[:large].size
  end

  def update_counts
    @small  = small
    @medium = medium
    @large  = large
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    return "No space available" if plate.empty?

    size = car_size.to_s.downcase.strip
    return "No space available" unless ['small', 'medium', 'large'].include?(size)

    # 1. Try direct allocation first to avoid unnecessary shuffling
    assigned_spot = try_direct_allocation(plate, size)
    if assigned_spot
      update_counts
      return "car with license plate no. #{plate} is parked at #{assigned_spot}"
    end

    # 2. Try global reallocation/shuffling of all parked cars + new car to maximize space
    current_cars = all_parked_cars + [{ plate: plate, size: size }]
    sorted_cars = current_cars.sort_by do |c|
      case c[:size]
      when 'large'  then 1
      when 'medium' then 2
      when 'small'  then 3
      else 4
      end
    end

    assignment = assign_cars_backtracking(sorted_cars, @small_capacity, @medium_capacity, @large_capacity)

    if assignment
      @parking_spots[:small].clear
      @parking_spots[:medium].clear
      @parking_spots[:large].clear

      assignment.each do |car, spot|
        @parking_spots[spot] << car
      end

      update_counts

      assigned_spot = assignment.find { |car, spot| car[:plate] == plate }[1]
      "car with license plate no. #{plate} is parked at #{assigned_spot}"
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    found_spot = nil
    found_car = nil

    [:small, :medium, :large].each do |spot|
      car = @parking_spots[spot].find { |c| c[:plate].to_s.downcase == plate.downcase }
      if car
        found_spot = spot
        found_car = car
        break
      end
    end

    if found_car
      @parking_spots[found_spot].delete(found_car)
      update_counts
    end

    "car with license plate no. #{plate} exited"
  end

  private

  def try_direct_allocation(plate, size)
    car = { plate: plate, size: size }
    if size == 'small'
      if small > 0
        @parking_spots[:small] << car
        return :small
      elsif medium > 0
        @parking_spots[:medium] << car
        return :medium
      elsif large > 0
        @parking_spots[:large] << car
        return :large
      end
    elsif size == 'medium'
      if medium > 0
        @parking_spots[:medium] << car
        return :medium
      elsif large > 0
        @parking_spots[:large] << car
        return :large
      end
    elsif size == 'large'
      if large > 0
        @parking_spots[:large] << car
        return :large
      end
    end
    nil
  end

  def all_parked_cars
    @parking_spots[:small] + @parking_spots[:medium] + @parking_spots[:large]
  end

  def assign_cars_backtracking(cars, s_cap, m_cap, l_cap, assignments = [])
    return assignments if cars.empty?

    car = cars.first
    remaining_cars = cars[1..-1]

    allowed_spots = case car[:size]
                    when 'large'  then [:large]
                    when 'medium' then [:medium, :large]
                    when 'small'  then [:small, :medium, :large]
                    else []
                    end

    allowed_spots.each do |spot|
      case spot
      when :small
        if s_cap > 0
          res = assign_cars_backtracking(remaining_cars, s_cap - 1, m_cap, l_cap, assignments + [[car, :small]])
          return res if res
        end
      when :medium
        if m_cap > 0
          res = assign_cars_backtracking(remaining_cars, s_cap, m_cap - 1, l_cap, assignments + [[car, :medium]])
          return res if res
        end
      when :large
        if l_cap > 0
          res = assign_cars_backtracking(remaining_cars, s_cap, m_cap, l_cap - 1, assignments + [[car, :large]])
          return res if res
        end
      end
    end

    nil
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate, :license

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @license = @license_plate
    @car_size = car_size.to_s.downcase.strip
    @entry_time = entry_time
  end

  def duration_hours
    hours = (Time.now - @entry_time) / 3600.0
    hours < 0 ? 0.0 : hours
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
    duration = duration_hours.to_f
    return 0.0 if duration <= 0.25

    size = car_size.to_s.downcase.strip
    rate = RATES[size] || 0.0
    max_fee = MAX_FEE[size] || 0.0

    billed_hours = duration.ceil
    fee = billed_hours * rate
    [fee.to_f, max_fee.to_f].min
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :tix_in_flight

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    clean_plate = plate.to_s.strip
    clean_size = size.to_s.downcase.strip

    if clean_plate.empty? || !['small', 'medium', 'large'].include?(clean_size)
      return { success: false, message: "No space available", ok: false, msg: "No space available" }
    end

    verdict = @garage.admit_car(clean_plate, clean_size)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(clean_plate, clean_size)
      @tix_in_flight[clean_plate] = ticket
      {
        success: true,
        message: verdict,
        ticket: ticket,
        ok: true,
        msg: verdict,
        tix: ticket
      }
    else
      {
        success: false,
        message: verdict,
        ok: false,
        msg: verdict
      }
    end
  end

  def exit_car(plate)
    clean_plate = plate.to_s.strip
    matching_key = @tix_in_flight.keys.find { |k| k.downcase == clean_plate.downcase }
    ticket = matching_key ? @tix_in_flight[matching_key] : nil

    unless ticket
      return {
        success: false,
        message: "No ticket found for license plate: #{clean_plate}",
        ok: false,
        msg: "nope"
      }
    end

    dur = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, dur)
    result = @garage.exit_car(ticket.license_plate) rescue "car with license plate no. #{ticket.license_plate} exited"

    @tix_in_flight.delete(matching_key)

    {
      success: true,
      message: "car with license plate no. #{ticket.license_plate} exited",
      fee: fee,
      duration_hours: dur,
      ok: true,
      msg: result,
      hours: dur
    }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @tix_in_flight.size,
      total_available: @garage.small + @garage.medium + @garage.large,
      small_open: @garage.small,
      med_open: @garage.medium,
      lrg_open: @garage.large,
      spots_left: @garage.small + @garage.medium + @garage.large,
      ticking: @tix_in_flight.size
    }
  end

  def find_ticket(plate)
    clean_plate = plate.to_s.strip.downcase
    matching_key = @tix_in_flight.keys.find { |k| k.downcase == clean_plate }
    matching_key ? @tix_in_flight[matching_key] : nil
  end
end