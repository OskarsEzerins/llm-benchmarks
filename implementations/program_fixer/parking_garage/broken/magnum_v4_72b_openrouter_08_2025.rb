require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large

  def initialize(small, medium, large)
    @small  = small.to_i
    @medium = medium.to_i
    @large  = large.to_i

    @parking_spots = {
      small_spot:   [],
      medium_spot:  [],
      large_spot:   []
    }
  end

  def admit_car(license_plate, car_size)
    car_size = car_size.downcase

    return "Invalid car size" unless ['small', 'medium', 'large'].include?(car_size)
    return "Invalid license plate" if license_plate.nil? || license_plate.strip.empty?

    car = { plate: license_plate.to_s, size: car_size }

    case car_size
    when 'small'
      if @small > 0
        @parking_spots[:small_spot] << car
        @small -= 1
        parking_status(car, 'small')
      elsif @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        parking_status
      end

    when 'medium'
      if @medium > 0
        @parking_spots[:medium_spot] << car
        @medium -= 1
        parking_status(car, 'medium')
      elsif @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_medium(car)
      end

    when 'large'
      if @large > 0
        @parking_spots[:large_spot] << car
        @large -= 1
        parking_status(car, 'large')
      else
        shuffle_large(car)
      end
    end
  end

  def exit_car(license_plate)
    return "Invalid license plate" if license_plate.nil? || license_plate.strip.empty?

    small_car  = @parking_spots[:small_spot].find { |c| c[:plate] == license_plate.to_s }
    medium_car = @parking_spots[:medium_spot].find { |c| c[:plate] == license_plate.to_s }
    large_car  = @parking_spots[:large_spot].find { |c| c[:plate] == license_plate.to_s }

    if small_car
      @parking_spots[:small_spot].delete(small_car)
      @small += 1
      exit_status(license_plate)
    elsif medium_car
      @parking_spots[:medium_spot].delete(medium_car)
      @medium += 1
      exit_status(license_plate)
    elsif large_car
      @parking_spots[:large_spot].delete(large_car)
      @large += 1
      exit_status(license_plate)
    else
      exit_status
    end
  end

  def shuffle_medium(car)
    victim = (@parking_spots[:large_spot] + @parking_spots[:medium_spot]).sample
    return parking_status unless victim

    spot = @parking_spots.key(victim) || :small_spot
    @parking_spots[spot].delete(victim)
    @parking_spots[:small_spot] << victim
    @parking_spots[spot] << car
    parking_status(car, spot.to_s.sub('_spot', ''))
  end

  def shuffle_large(car)
    first_medium = @parking_spots[:large_spot].find { |c| c[:size] == 'medium' }
    if first_medium && @medium > 0
      @parking_spots[:large_spot].delete(first_medium)
      @parking_spots[:medium_spot] << first_medium
      @medium -= 1
      @parking_spots[:large_spot] << car
      parking_status(car, 'large')
    else
      parking_status
    end
  end

  def parking_status(car = nil, space = nil)
    if car && space
      "car with license plate no. #{car[:plate]} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    plate ? "car with license plate no. #{plate} exited" : "Invalid license plate"
  end
end

class ParkingTicket
  attr_reader :id, :license_plate, :car_size, :entry_time

  def initialize(license_plate, car_size, entry_time = Time.now)