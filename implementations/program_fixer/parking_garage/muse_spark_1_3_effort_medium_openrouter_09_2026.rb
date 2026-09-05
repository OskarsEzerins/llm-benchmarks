require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @small = 0 if @small < 0
    @medium = 0 if @medium < 0
    @large = 0 if @large < 0

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
    @parking_spots[:tiny_spot] = @parking_spots[:small]
    @parking_spots[:mid_spot] = @parking_spots[:medium]
    @parking_spots[:grande_spot] = @parking_spots[:large]
  end

  def admit_car(license_plate_no, car_size)
    return parking_status if license_plate_no.nil? || car_size.nil?

    plate_str = license_plate_no.to_s.strip
    return parking_status if plate_str.empty?

    size_str = car_size.to_s.strip.downcase
    unless %w[small medium large].include?(size_str)
      return parking_status
    end

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
  end

  def exit_car(license_plate_no)
    return exit_status(nil) if license_plate_no.nil?

    plate_str = license_plate_no.to_s

    small_car = @parking_spots[:small].detect { |c| c[:plate].to_s == plate_str }
    medium_car = @parking_spots[:medium].detect { |c| c[:plate].to_s == plate_str }
    large_car = @parking_spots[:large].detect { |c| c[:plate].to_s == plate_str }

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
      exit_status(nil, plate_str)
    end
  end

  def shuffle_medium(kar)
    if @small > 0
      victim = @parking_spots[:medium].find { |c| c[:size].to_s == 'small' }
      if victim
        @parking_spots[:medium].delete(victim)
        @medium += 1
        @parking_spots[:small] << victim
        @small -= 1
        @parking_spots[:medium] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      end
      victim_large = @parking_spots[:large].find { |c| c[:size].to_s == 'small' }
      if victim_large
        @parking_spots[:large].delete(victim_large)
        @large += 1
        @parking_spots[:small] << victim_large
        @small -= 1
        @parking_spots[:large] << kar
        @large -= 1
        return parking_status(kar, 'large')
      end
    end
    parking_status
  end

  def shuffle_large(kar)
    victim = @parking_spots[:large].find do |c|
      sz = c[:size].to_s
      (sz == 'medium' && @medium > 0) ||
        (sz == 'small' && (@small > 0 || @medium > 0))
    end
    if victim
      @parking_spots[:large].delete(victim)
      @large += 1
      vsize = victim[:size].to_s
      if vsize == 'medium'
        @parking_spots[:medium] << victim
        @medium -= 1
      else
        if @small > 0
          @parking_spots[:small] << victim
          @small -= 1
        else
          @parking_spots[:medium] << victim
          @medium -= 1
        end
      end
      @parking_spots[:large] << kar
      @large -= 1
      return parking_status(kar, 'large')
    end
    parking_status
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil, original_plate = nil)
    if plate
      "car with license plate no. #{plate} exited"
    else
      if original_plate && !original_plate.to_s.strip.empty?
        "No car with license plate no. #{original_plate} found"
      else
        "No car found"
      end
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :license_plate, :car_size, :license

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.nil? ? "" : license_plate.to_s
    @license = @license_plate
    @car_size = car_size.nil? ? "" : car_size.to_s.strip.downcase
    @car_siez = @car_size
    @entry_time = entry_time || Time.now
  end

  def car_siez
    @car_size
  end

  def duration_hours
    begin
      ((Time.now - @entry_time) / 3600.0).to_f
    rescue
      0.0
    end
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
    begin
      return 0.0 if car_size.nil? || duration_hours.nil?
      size_str = car_size.to_s.strip.downcase
      return 0.0 unless %w[small medium large].include?(size_str)
      duration = Float(duration_hours) rescue (return 0.0)
      return 0.0 if duration < 0
      return 0.0 if duration <= 0.25
      hours = duration.ceil
      rate = RATES[size_str.to_sym]
      total = hours * rate
      max = MAX_FEE[size_str]
      [total, max].min.to_f
    rescue
      0.0
    end
  end
end

class ParkingGarageManager
  def initialize(*args, small_spots: nil, medium_spots: nil, large_spots: nil, small: nil, medium: nil, large: nil)
    s = small_spots
    m = medium_spots
    l = large_spots
    s = small if s.nil? && !small.nil?
    m = medium if m.nil? && !medium.nil?
    l = large if l.nil? && !large.nil?
    s = args[0] if s.nil? && args.length > 0
    m = args[1] if m.nil? && args.length > 1
    l = args[2] if l.nil? && args.length > 2
    s = 0 if s.nil?
    m = 0 if m.nil?
    l = 0 if l.nil?
    @garage = ParkingGarage.new(s.to_i, m.to_i, l.to_i)
    @total_capacity = s.to_i + m.to_i + l.to_i
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def garage
    @garage
  end

  def admit_car(plate, size)
    begin
      verdict = @garage.admit_car(plate, size)
    rescue
      verdict = "No space available"
    end
    if verdict.to_s.include?('parked')
      begin
        plate_str = plate.to_s
      rescue
        plate_str = ""
      end
      size_str = size.to_s.strip.downcase rescue ""
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict, ticket: nil }
    end
  end

  def exit_car(plate)
    begin
      plate_str = plate.nil? ? "" : plate.to_s
    rescue
      return { success: false, message: "No ticket found" }
    end
    ticket = @tix_in_flight[plate_str]
    ticket = @tix_in_flight[plate] if ticket.nil? && !plate.nil?
    return { success: false, message: "No ticket found for #{plate_str}" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    duration = ticket.duration_hours
    begin
      result = @garage.exit_car(plate_str)
    rescue
      result = "car with license plate no. #{plate_str} exited"
    end
    @tix_in_flight.delete(plate_str)
    @tix_in_flight.delete(plate)
    { success: true, message: result, fee: fee.to_f, duration_hours: duration.to_f }
  end

  def garage_status
    small_a = @garage.small
    medium_a = @garage.medium
    large_a = @garage.large
    total_available = small_a + medium_a + large_a
    total_occupied = @total_capacity - total_available
    total_occupied = 0 if total_occupied < 0
    {
      small_available: small_a,
      medium_available: medium_a,
      large_available: large_a,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    begin
      return nil if plate.nil?
      @tix_in_flight.fetch(plate.to_s, nil)
    rescue
      nil
    end
  end
end