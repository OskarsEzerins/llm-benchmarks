require 'securerandom'

class ParkingGarage
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

  def admit_car(license_plate_no, car_size)
    plate = (license_plate_no.to_s).to_s
    size = car_size.to_s.downcase

    return 'No space available' unless valid_size?(size)

    spot = allocate_spot(size)
    if spot
      @spots[spot] << { plate: plate, size: size }
      "car with license plate no. #{plate} is parked at #{spot}"
    else
      'No space available'
    end
  end

  def exit_car(license_plate_no)
    plate = (license_plate_no.to_s).to_s
    spot_found = nil
    @spots.each do |spot, arr|
      idx = arr.find_index { |c| c[:plate] == plate }
      if idx
        arr.delete_at(idx)
        spot_found = spot
        break
      end
    end
    if spot_found
      "car with license plate no. #{plate} exited"
    else
      'Ghost car?'
    end
  end

  def available_spots(space)
    key = space.to_s.downcase.to_sym
    return 0 unless @capacity.key?(key)
    @capacity[key] - @spots[key].length
  end

  def total_occupied
    @spots.values.map(&:length).sum
  end

  def total_available_spots
    @capacity.values.sum - total_occupied
  end

  private

  def valid_size?(size)
    %w(small medium large).include?(size)
  end

  def allocate_spot(size)
    case size
    when 'small'
      return :small if available_spots(:small) > 0
      return :medium if available_spots(:medium) > 0
      return :large if available_spots(:large) > 0
    when 'medium'
      return :medium if available_spots(:medium) > 0
      return :large if available_spots(:large) > 0
    when 'large'
      return :large if available_spots(:large) > 0
    end
    nil
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0)
  end

  def valid?
    duration_hours <= 24.0
  end
end

class ParkingFeeCalculator
  MAX_FEE = {
    small:  20.0,
    medium: 30.0,
    large:  50.0
  }

  RATES = {
    small: 2.0,
    medium: 3.0,
    large: 5.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil?
    size = (car_size.to_s).downcase.to_sym
    rate = RATES[size]
    return 0.0 if rate.nil?
    # Grace period
    return 0.0 if duration_hours <= 0.25
    billable_hours = duration_hours - 0.25
    billable_hours = billable_hours.ceil
    total = billable_hours * rate
    max = MAX_FEE[size]
    total > max ? max : total
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots:, large_spots:)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    plate_str = (plate.to_s).strip
    return { ok: false, msg: 'Invalid license plate' } if plate_str.empty?

    size_str = (size.to_s).downcase
    unless %w(small medium large).include?(size_str)
      return { ok: false, msg: 'Invalid car size' }
    end

    verdict = @garage.admit_car(plate_str, size_str)
    if verdict.include?('No space available')
      { ok: false, msg: verdict }
    else
      ticket = ParkingTicket.new(plate_str, size_str, Time.now)
      @tix_in_flight[plate_str] = ticket
      { ok: true, msg: verdict, tix: ticket }
    end
  end

  def exit_car(plate)
    plate_str = (plate.to_s).strip
    unless plate_str && !plate_str.empty?
      return { ok: false, msg: 'Invalid license plate' }
    end

    ticket = @tix_in_flight[plate_str]
    return { ok: false, msg: 'nope' } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)
    @tix_in_flight.delete(plate_str)
    { ok: true, msg: result, fee: fee, hours: duration }
  end

  def garage_status
    {
      small_open: @garage.available_spots(:small),
      med_open:   @garage.available_spots(:medium),
      lrg_open:   @garage.available_spots(:large),
      spots_left: @garage.total_available_spots,
      ticking:    @tix_in_flight.size
    }
  end

  def find_ticket(plate)
    @tix_in_flight.fetch(plate, nil)
  end
end