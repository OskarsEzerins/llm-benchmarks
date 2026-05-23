require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small_capacity, :medium_capacity, :large_capacity

  def initialize(small, medium, large)
    @small_capacity = [small.to_i, 0].max
    @medium_capacity = [medium.to_i, 0].max
    @large_capacity = [large.to_i, 0].max

    @parking_spots = {
      'small' => [],
      'medium' => [],
      'large' => []
    }
  end

  def small
    [@small_capacity - @parking_spots['small'].size, 0].max
  end

  def medium
    [@medium_capacity - @parking_spots['medium'].size, 0].max
  end

  def large
    [@large_capacity - @parking_spots['large'].size, 0].max
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size = car_size.to_s.strip.downcase
    
    return "No space available" if plate.empty? || !['small', 'medium', 'large'].include?(size)

    optimize_parking

    kar = { plate: plate, size: size }

    case size
    when 'small'
      if small > 0
        @parking_spots['small'] << kar
        "car with license plate no. #{plate} is parked at small"
      elsif medium > 0
        @parking_spots['medium'] << kar
        "car with license plate no. #{plate} is parked at medium"
      elsif large > 0
        @parking_spots['large'] << kar
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    when 'medium'
      if medium > 0
        @parking_spots['medium'] << kar
        "car with license plate no. #{plate} is parked at medium"
      elsif large > 0
        @parking_spots['large'] << kar
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    when 'large'
      if large > 0
        @parking_spots['large'] << kar
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    ['small', 'medium', 'large'].each do |type|
      car = @parking_spots[type].find { |c| c[:plate] == plate }
      if car
        @parking_spots[type].delete(car)
        return "car with license plate no. #{plate} exited"
      end
    end
    "car with license plate no. #{plate} not found"
  end

  private

  def optimize_parking
    loop do
      moved = false
      if small > 0
        small_car_in_med = @parking_spots['medium'].find { |c| c[:size] == 'small' }
        if small_car_in_med
          @parking_spots['medium'].delete(small_car_in_med)
          @parking_spots['small'] << small_car_in_med
          moved = true
          next
        end

        small_car_in_lrg = @parking_spots['large'].find { |c| c[:size] == 'small' }
        if small_car_in_lrg
          @parking_spots['large'].delete(small_car_in_lrg)
          @parking_spots['small'] << small_car_in_lrg
          moved = true
          next
        end
      end

      if medium > 0
        med_car_in_lrg = @parking_spots['large'].find { |c| c[:size] == 'medium' }
        if med_car_in_lrg
          @parking_spots['large'].delete(med_car_in_lrg)
          @parking_spots['medium'] << med_car_in_lrg
          moved = true
          next
        end

        small_car_in_lrg = @parking_spots['large'].find { |c| c[:size] == 'small' }
        if small_car_in_lrg
          @parking_spots['large'].delete(small_car_in_lrg)
          @parking_spots['medium'] << small_car_in_lrg
          moved = true
          next
        end
      end
      break unless moved
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = "TK-#{SecureRandom.hex(4).upcase}"
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.strip.downcase
    @entry_time = entry_time
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
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }

  MAX_FEES = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.strip.downcase
    duration = duration_hours.to_f
    return 0.0 if duration <= 0.25 || duration < 0

    rate = RATES[size] || 0.0
    max = MAX_FEES[size] || 0.0

    hours = duration.ceil.to_f
    fee = hours * rate
    [fee, max].min
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small_spots, medium_spots, large_spots)
    @garage = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str = size.to_s.strip.downcase

    verdict = @garage.admit_car(plate_str, size_str)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: "No space available" }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tix_in_flight[plate_str]
    result = @garage.exit_car(plate_str)

    if result.include?('exited')
      duration = ticket ? ticket.duration_hours : 0.0
      size = ticket ? ticket.car_size : 'small'
      fee = @fee_calculator.calculate_fee(size, duration)
      @tix_in_flight.delete(plate_str)
      { success: true, message: result, fee: fee, duration_hours: duration }
    else
      { success: false, message: "car with license plate no. #{plate_str} not found" }
    end
  end

  def garage_status
    s_avail = @garage.small
    m_avail = @garage.medium
    l_avail = @garage.large
    total_occ = @garage.parking_spots.values.map(&:size).sum
    total_avail = s_avail + m_avail + l_avail
    {
      small_available: s_avail,
      medium_available: m_avail,
      large_available: l_avail,
      total_occupied: total_occ,
      total_available: total_avail
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end
end