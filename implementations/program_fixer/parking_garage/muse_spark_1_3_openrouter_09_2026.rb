require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i rescue 0
    @medium = medium.to_i rescue 0
    @large = large.to_i rescue 0
    @small = 0 if @small < 0
    @medium = 0 if @medium < 0
    @large = 0 if @large < 0
    @small_capacity = @small
    @medium_capacity = @medium
    @large_capacity = @large
    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    return parking_status if license_plate_no.nil? || car_size.nil?
    plate_str = license_plate_no.to_s
    return parking_status if plate_str.strip.empty?
    size_str = car_size.to_s.strip.downcase
    unless %w[small medium large].include?(size_str)
      return parking_status
    end
    return parking_status if car_already_parked?(plate_str)

    kar = { plate: plate_str, size: size_str }

    case size_str
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        parking_status
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_medium(kar)
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        parking_status(kar, 'large')
      else
        shuffle_large(kar)
      end
    else
      parking_status
    end
  rescue
    parking_status
  end

  def exit_car(license_plate_no)
    return exit_status(nil) if license_plate_no.nil?
    plate_str = license_plate_no.to_s
    small_car = @parking_spots[:small].detect { |c| c[:plate] == plate_str }
    medium_car = @parking_spots[:medium].find { |c| c[:plate] == plate_str }
    large_car = @parking_spots[:large].find { |c| c[:plate] == plate_str }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      exit_status(plate_str)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      exit_status(plate_str)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      exit_status(plate_str)
    else
      "No car found with license plate no. #{plate_str}"
    end
  rescue
    "No car found with license plate no. #{license_plate_no}"
  end

  def shuffle_medium(kar)
    # Try to free a medium spot by moving a small car from medium to small
    if @small > 0
      victim = @parking_spots[:medium].find { |c| c[:size] == 'small' }
      if victim
        @parking_spots[:medium].delete(victim)
        @parking_spots[:small] << victim
        @small -= 1
        @medium += 1
        @parking_spots[:medium] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      end
    end
    # Try to free large for medium by moving small/medium out if possible
    parking_status
  rescue
    parking_status
  end

  def shuffle_large(kar)
    # Move a medium car from large to medium if medium space available
    first_medium = @parking_spots[:large].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large].delete(first_medium)
      @parking_spots[:medium] << first_medium
      @medium -= 1
      @large += 1
      @parking_spots[:large] << kar
      @large -= 1
      return parking_status(kar, 'large')
    end
    # Move a small car from large to small/medium if available
    first_small = @parking_spots[:large].find { |c| c[:size] == 'small' }
    if first_small
      if @small > 0
        @parking_spots[:large].delete(first_small)
        @parking_spots[:small] << first_small
        @small -= 1
        @large += 1
        @parking_spots[:large] << kar
        @large -= 1
        return parking_status(kar, 'large')
      elsif @medium > 0
        @parking_spots[:large].delete(first_small)
        @parking_spots[:medium] << first_small
        @medium -= 1
        @large += 1
        @parking_spots[:large] << kar
        @large -= 1
        return parking_status(kar, 'large')
      end
    end
    parking_status
  rescue
    parking_status
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    if plate && !plate.to_s.strip.empty?
      "car with license plate no. #{plate} exited"
    else
      "No car found with license plate no. #{plate}"
    end
  end

  private

  def car_already_parked?(plate_str)
    @parking_spots.values.any? { |arr| arr.any? { |c| c[:plate] == plate_str } }
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate, :license

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s
    @license = @license_plate
    @license_plate_no = @license_plate
    @car_size = car_size.to_s.strip.downcase
    @car_siez = @car_size
    if entry_time.is_a?(Time)
      @entry_time = entry_time
    else
      @entry_time = Time.now
    end
  end

  def license_plate_no
    @license_plate
  end

  def car_siez
    @car_size
  end

  def duration_hours
    ((Time.now - @entry_time) / 3600.0).to_f
  rescue
    0.0
  end

  def valid?
    duration_hours <= 24
  end

  private

  def generate_ticket_id
    "TK-#{rand(9999)}"
  end
end

class ParkingFeeCalculator
  RATES = {
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0,
    small: 2.0,
    medium: 3.0,
    large: 5.0
  }

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if car_size.nil? || duration_hours.nil?
    begin
      duration = Float(duration_hours)
    rescue
      return 0.0
    end
    return 0.0 if duration.nil? || duration < 0 || duration.nan? rescue return 0.0
    return 0.0 if duration.infinite?
    size = car_size.to_s.strip.downcase
    return 0.0 unless %w[small medium large].include?(size)
    return 0.0 if duration <= 0.25
    rate = RATES[size] || RATES[size.to_sym]
    max = MAX_FEE[size]
    hours = duration.ceil
    total = hours * rate
    [total, max].min.to_f
  rescue
    0.0
  end
end

class ParkingGarageManager
  attr_reader :garage

  def initialize(small = 0, medium = 0, large = 0, small_spots: nil, medium_spots: nil, large_spots: nil)
    if small.is_a?(Hash) && medium == 0 && large == 0 && small_spots.nil?
      h = small
      s = h[:small] || h[:small_spots] || h['small'] || h['small_spots'] || 0
      m = h[:medium] || h[:medium_spots] || h['medium'] || h['medium_spots'] || 0
      l = h[:large] || h[:large_spots] || h['large'] || h['large_spots'] || 0
      small = s
      medium = m
      large = l
    end
    small = small_spots unless small_spots.nil?
    medium = medium_spots unless medium_spots.nil?
    large = large_spots unless large_spots.nil?
    begin
      s = Integer(small) rescue small.to_i rescue 0
      m = Integer(medium) rescue medium.to_i rescue 0
      l = Integer(large) rescue large.to_i rescue 0
    rescue
      s = 0
      m = 0
      l = 0
    end
    @garage = ParkingGarage.new(s, m, l)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    begin
      return { success: false, message: "No space available" } if plate.nil? || size.nil?
      plate_s = plate.to_s
      return { success: false, message: "No space available" } if plate_s.strip.empty?
      size_s = size.to_s.strip.downcase
      unless %w[small medium large].include?(size_s)
        return { success: false, message: "No space available" }
      end
      verdict = @garage.admit_car(plate_s, size_s)
      if verdict.to_s.include?('parked')
        ticket = ParkingTicket.new(plate_s, size_s)
        @tix_in_flight[plate_s] = ticket
        { success: true, message: verdict, ticket: ticket }
      else
        { success: false, message: verdict }
      end
    rescue => e
      { success: false, message: "No space available" }
    end
  end

  def exit_car(plate)
    begin
      return { success: false, message: "No active ticket found" } if plate.nil?
      key = plate.to_s
      ticket = @tix_in_flight[key]
      return { success: false, message: "No active ticket found for #{key}" } unless ticket
      fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
      duration = ticket.duration_hours.to_f
      result = @garage.exit_car(key)
      @tix_in_flight.delete(key)
      { success: true, message: result, fee: fee.to_f, duration_hours: duration }
    rescue => e
      { success: false, message: "No active ticket found" }
    end
  end

  def garage_status
    begin
      s = @garage.small
      m = @garage.medium
      l = @garage.large
      occupied = @garage.parking_spots.values.map(&:size).sum
      available = s + m + l
      {
        small_available: s,
        medium_available: m,
        large_available: l,
        total_occupied: occupied,
        total_available: available,
        small_open: s,
        med_open: m,
        lrg_open: l,
        spots_left: available,
        ticking: @tix_in_flight.size
      }
    rescue
      {
        small_available: 0,
        medium_available: 0,
        large_available: 0,
        total_occupied: 0,
        total_available: 0
      }
    end
  end

  def find_ticket(plate)
    return nil if plate.nil?
    @tix_in_flight[plate.to_s]
  rescue
    nil
  end
end