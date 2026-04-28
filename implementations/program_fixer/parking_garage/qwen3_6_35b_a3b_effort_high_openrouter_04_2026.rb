require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small: [],
      medium: [],
      large: []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    size  = car_size.to_s.downcase.strip

    return nil if plate.empty? || !%w(small medium large).include?(size)

    car = { plate: plate, size: size }

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << car
        @small -= 1
      elsif @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
      else
        return "No space available"
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << car
        @medium -= 1
      elsif @large > 0
        @parking_spots[:large] << car
        @large -= 1
      else
        medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
        if medium_in_large && @medium > 0
          @parking_spots[:large].delete(medium_in_large)
          @parking_spots[:medium] << medium_in_large
          @parking_spots[:large] << car
          @large -= 1
        else
          return "No space available"
        end
      end

    when 'large'
      if @large > 0
        @parking_spots[:large] << car
        @large -= 1
      else
        freed = false
        @parking_spots[:large].each do |car_in_large|
          if car_in_large[:size] == 'medium' && @medium > 0
            @parking_spots[:large].delete(car_in_large)
            @parking_spots[:medium] << car_in_large
            @medium -= 1
            @large += 1
            freed = true
            break
          end
        end

        if freed
          @parking_spots[:large] << car
          @large -= 1
        else
          return "No space available"
        end
      end
    end

    "car with license plate no. #{plate} is parked at #{size}"
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    return nil if plate.empty?

    car = @parking_spots[:small].find { |c| c[:plate] == plate } ||
          @parking_spots[:medium].find { |c| c[:plate] == plate } ||
          @parking_spots[:large].find { |c| c[:plate] == plate }

    if car
      @parking_spots[car[:size]].delete(car)
      case car[:size]
      when 'small' then @small += 1
      when 'medium' then @medium += 1
      when 'large' then @large += 1
      end
    end

    "car with license plate no. #{plate} exited"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :plate

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id         = SecureRandom.hex(8)
    @plate      = license_plate.to_s
    @car_size   = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    (Time.now - entry_time) / 3600.0
  end

  def valid?
    duration_hours < 24.0
  end
end

class ParkingFeeCalculator
  RATES = { small: 2.0, medium: 3.0, large: 5.0 }
  MAX_FEE = { small: 20.0, medium: 30.0, large: 50.0 }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours.nil? || duration_hours < 0
    size = car_size.to_s.downcase
    return 0.0 unless RATES.key?(size)

    billable_hours = [0, duration_hours - 0.25].ceil
    rate = RATES[size]
    total = billable_hours * rate
    [total, MAX_FEE[size]].min
  end
end

class ParkingGarageManager
  def initialize(small, medium, large)
    @garage         = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
  end

  def admit_car(plate, size)
    msg = @garage.admit_car(plate, size)
    return { success: false, message: msg, ticket: nil } if msg.nil?

    if msg.include?('parked at')
      ticket = ParkingTicket.new(plate, size)
      @active_tickets[plate.to_s] = ticket
      { success: true, message: msg, ticket: ticket }
    else
      { success: false, message: msg, ticket: nil }
    end
  end

  def exit_car(plate)
    ticket = @active_tickets.delete(plate.to_s)
    return { success: false, message: "No ticket found", fee: 0.0, duration_hours: 0.0 } unless ticket

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    msg = @garage.exit_car(plate)

    { success: true, message: msg, fee: fee, duration_hours: duration }
  end

  def garage_status
    {
      small_available: @garage.small,
      medium_available: @garage.medium,
      large_available: @garage.large,
      total_occupied: @active_tickets.size,
      total_available: @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @active_tickets[plate.to_s]
  end
end