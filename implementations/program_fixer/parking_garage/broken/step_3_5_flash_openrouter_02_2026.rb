require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i
    @parking_spots = {
      small:  [],
      medium: [],
      large:  []
    }
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    return "Invalid license plate" if plate.empty?

    size = car_size.to_s.strip.downcase
    return "Invalid car size" unless %w[small medium large].include?(size)

    case size
    when 'small'
      if @small > 0
        @parking_spots[:small] << { plate: plate, size: size }
        @small -= 1
        "car with license plate no. #{plate} is parked at small"
      elsif @medium > 0
        @parking_spots[:medium] << { plate: plate, size: size }
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << { plate: plate, size: size }
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << { plate: plate, size: size }
        @medium -= 1
        "car with license plate no. #{plate} is parked at medium"
      elsif @large > 0
        @parking_spots[:large] << { plate: plate, size: size }
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        "No space available"
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << { plate: plate, size: size }
        @large -= 1
        "car with license plate no. #{plate} is parked at large"
      else
        # Try to free a large spot by moving a medium car from large to medium
        medium_in_large = @parking_spots[:large].find { |c| c[:size] == 'medium' }
        if medium_in_large && @medium > 0
          @parking_spots[:large].delete(medium_in_large)
          @large += 1
          @parking_spots[:medium] << medium_in_large
          @medium -= 1
          @parking_spots[:large] << { plate: plate, size: size }
          @large -= 1
          "car with license plate no. #{plate} is parked at large"
        else
          "No space available"
        end
      end
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip

    car = @parking_spots[:small].find { |c| c[:plate] == plate }
    if car
      @parking_spots[:small].delete(car)
      @small += 1
      return "car with license plate no. #{plate} exited"
    end

    car = @parking_spots[:medium].find { |c| c[:plate] == plate }
    if car
      @parking_spots[:medium].delete(car)
      @medium += 1
      return "car with license plate no. #{plate} exited"
    end

    car = @parking_spots[:large].find { |c| c[:plate] == plate }
    if car
      @parking_spots[:large].delete(car)
      @large += 1
      return "car with license plate no. #{plate} exited"
    end

    "Car not found"
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id        = SecureRandom.uuid
    @license   = license_plate.to_s
    @car_size  = car_size.to_s.downcase
    @entry_time = entry_time
  end

  def duration_hours
    [(Time.now - @entry_time) / 3600.0, 0].max
  end

  def valid?
    duration_hours < 24.0
  end
end

class ParkingFeeCalculator
  RATES = {
    small:  2.0,
    medium: 3.0,
    large:  5.0
  }

  MAX_FEE = {
    'small'  => 20.0,
    'medium' => 30.0,
    'large'  => 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if duration_hours <= 0.25

    size = car_size.to_s.downcase
    rate = RATES[size.to_sym] || 0.0
    max_fee = MAX_FEE[size] || Float::INFINITY

    billable_hours = duration_hours - 0.25
    hours_to_charge = billable_hours.ceil
    fee = hours_to_charge * rate
    [fee, max_fee].min
  end
end

class ParkingGarageManager
  def initialize(small_spots:, medium_spots, large_spots)
    @garage         = ParkingGarage.new(small_spots, medium_spots, large_spots)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight  = {}
  end

  def admit_car(plate, size)
    plate_str = plate.to_s.strip
    size_str = size.to_s.strip.downcase

    return { success: false, message: "Invalid license plate" } if plate_str.empty?
    return { success: false, message: "Invalid car size" } unless %w[small medium large].include?(size_str)
    return { success: false, message: "Car already parked" } if @tix_in_flight.key?(plate_str)

    verdict = @garage.admit_car(plate_str, size_str)

    if verdict.to_s.include?('parked')
      ticket = ParkingTicket.new(plate_str, size_str)
      @tix_in_flight[plate_str] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    plate_str = plate.to_s.strip
    ticket = @tix_in_flight[plate_str]

    return { success: false, message: "Ticket not found for plate #{plate_str}" } unless ticket

    fee = @fee_calculator.calculate_fee(ticket.car_size, ticket.duration_hours)
    result = @garage.exit_car(plate_str)
    @tix_in_flight.delete(plate_str)

    { success: true, message: result, fee: fee, duration_hours: ticket.duration_hours }
  end

  def garage_status
    {
      small_available:  @garage.small,
      medium_available: @garage.medium,
      large_available:  @garage.large,
      total_occupied:   @garage.parking_spots[:small].size + @garage.parking_spots[:medium].size + @garage.parking_spots[:large].size,
      total_available:  @garage.small + @garage.medium + @garage.large
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end
end