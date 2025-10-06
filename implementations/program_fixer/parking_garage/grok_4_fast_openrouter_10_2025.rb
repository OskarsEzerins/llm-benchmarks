require 'securerandom'

class ParkingGarage
  attr_reader :small, :medium, :large

  def initialize(small, medium, large)
    @small = small.to_i
    @medium = medium.to_i
    @large = large.to_i
    @spots = { small: [], medium: [], large: [] }
  end

  def admit_car(license_plate, car_size)
    plate = license_plate.to_s.strip
    return "Invalid license plate" if plate.empty?

    size = car_size.to_s.downcase
    return "Invalid car size" unless %w[small medium large].include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @spots[:small] << car
        @small -= 1
        return "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @spots[:medium] << car
        @medium -= 1
        return "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @spots[:large] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return "No space available"
      end
    when 'medium'
      if @medium > 0
        @spots[:medium] << car
        @medium -= 1
        return "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @spots[:large] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return "No space available"
      end
    when 'large'
      if @large > 0
        @spots[:large] << car
        @large -= 1
        return "car with license plate no. #{plate} is parked at large"
      else
        return shuffle_for_large(car)
      end
    end
  end

  def exit_car(license_plate)
    plate = license_plate.to_s.strip
    car = nil
    spot_type = nil

    if (car = @spots[:small].find { |c| c[:plate] == plate })
      spot_type = :small
    elsif (car = @spots[:medium].find { |c| c[:plate] == plate })
      spot_type = :medium
    elsif (car = @spots[:large].find { |c| c[:plate] == plate })
      spot_type = :large
    end

    if car
      @spots[spot_type].delete(car)
      case spot_type
      when :small; @small += 1
      when :medium; @medium += 1
      when :large; @large += 1
      end
      return "car with license plate no. #{plate} exited"
    else
      return "Car not found"
    end
  end

  private

  def shuffle_for_large(car)
    relocatable = []

    if @medium > 0
      med = @spots[:large].find { |c| c[:size] == 'medium' }
      relocatable << [med, :medium] if med
    end

    if @small > 0 && relocatable.empty?
      sm = @spots[:large].find { |c| c[:size] == 'small' }
      relocatable << [sm, :small] if sm
    end

    if @medium > 0 && @small == 0 && relocatable.empty?
      sm = @spots[:large].find { |c| c[:size] == 'small' }
      relocatable << [sm, :medium] if sm
    end

    return "No space available" unless relocatable.any?

    victim, target = relocatable.first
    @spots[:large].delete(victim)
    @spots[target] << victim
    @large += 1
    case target
    when :small; @small -= 1
    when :medium; @medium -= 1
    end

    @spots[:large] << car
    @large -= 1
    "car with license plate no. #{car[:plate]} is parked at large"
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @car_size = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - @entry_time) / 3600.0
  end

  def valid?
    (Time.now - @entry_time) < 24 * 3600
  end
end

class ParkingFeeCalculator
  def calculate_fee(car_size, duration_hours)
    size = car_size.to_s.downcase
    return 0.0 unless %w[small medium large].include?(size)

    return 0.0 if duration_hours <= 0.25

    hours_to_charge = (duration_hours - 0.25).ceil

    rate = case size
           when 'small' then 2.0
           when 'medium' then 3.0
           when 'large' then 5.0
           end

    total = hours_to_charge * rate

    max_fee = case size
              when 'small' then 20.0
              when 'medium' then 30.0
              when 'large' then 50.0
              end

    [total, max_fee].min
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage = ParkingGarage.new(small, medium, large)
    @total_spots = small + medium + large
    @fee_calculator = ParkingFeeCalculator.new
    @tickets = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    return { success: false, message: "Invalid license plate" } if plate_str.empty?

    size_str = size.to_s.downcase.strip
    return { success: false, message: "Invalid car size" } unless %w[small medium large].include?(size_str)

    verdict = @garage.admit_car(plate_str, size_str)

    if verdict.include?("parked")
      ticket = ParkingTicket.new(plate_str, size_str)
      @tickets[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    return { success: false, message: "Invalid license plate" } if plate_str.empty?

    ticket = @tickets[plate_str]
    return { success: false, message: "Ticket not found or expired" } unless ticket && ticket.valid?

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(plate_str)

    if result.include?("exited")
      @tickets.delete(plate_str)
      { success: true, message: result, fee: fee, duration_hours: duration }
    else
      { success: false, message: result || "Car not found" }
    end
  end

  def garage_status
    small_av = @garage.small
    med_av = @garage.medium
    large_av = @garage.large
    total_occupied = @tickets.size
    total_available = @total_spots - total_occupied
    {
      small_available: small_av,
      medium_available: med_av,
      large_available: large_av,
      total_occupied: total_occupied,
      total_available: total_available
    }
  end

  def find_ticket(plate)
    @tickets.fetch(plate.to_s.strip, nil)
  end
end