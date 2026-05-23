require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :spots, :capacity, :small, :medium, :large

  def initialize(small, medium, large)
    @small_orig = small.to_i
    @medium_orig = medium.to_i
    @large_orig = large.to_i

    @spots = {
      'small' => [],
      'medium' => [],
      'large' => []
    }

    @capacity = {
      'small' => @small_orig,
      'medium' => @medium_orig,
      'large' => @large_orig
    }

    @parking_spots = {
      tiny_spot: @spots['small'],
      mid_spot: @spots['medium'],
      grande_spot: @spots['large']
    }

    update_legacy_counters
  end

  def admit_car(license_plate_no, car_size)
    plate = license_plate_no.to_s.strip
    return "No space available" if plate.empty?

    size = car_size.to_s.downcase.strip
    return "No space available" unless ['small', 'medium', 'large'].include?(size)

    return "No space available" if find_car(plate)

    kar = { plate: plate, size: size }
    parked_at = nil

    case size
    when 'small'
      if @spots['small'].size < @capacity['small']
        @spots['small'] << kar
        parked_at = 'small'
      elsif @spots['medium'].size < @capacity['medium']
        @spots['medium'] << kar
        parked_at = 'medium'
      elsif @spots['large'].size < @capacity['large']
        @spots['large'] << kar
        parked_at = 'large'
      end
    when 'medium'
      if @spots['medium'].size < @capacity['medium']
        @spots['medium'] << kar
        parked_at = 'medium'
      elsif @spots['large'].size < @capacity['large']
        @spots['large'] << kar
        parked_at = 'large'
      else
        # Shuffle a small car from medium to small spot if possible
        shuffled = false
        @spots['medium'].each_with_index do |parked_car, idx|
          if parked_car[:size] == 'small' && @spots['small'].size < @capacity['small']
            @spots['small'] << parked_car
            @spots['medium'].delete_at(idx)
            @spots['medium'] << kar
            shuffled = true
            break
          end
        end
        parked_at = 'medium' if shuffled
      end
    when 'large'
      if @spots['large'].size < @capacity['large']
        @spots['large'] << kar
        parked_at = 'large'
      else
        # Shuffle a small/medium car from large to open smaller spots
        shuffled = false
        @spots['large'].each_with_index do |parked_car, idx|
          p_size = parked_car[:size]
          if p_size == 'medium' && @spots['medium'].size < @capacity['medium']
            @spots['medium'] << parked_car
            @spots['large'].delete_at(idx)
            @spots['large'] << kar
            shuffled = true
            break
          elsif p_size == 'small'
            if @spots['small'].size < @capacity['small']
              @spots['small'] << parked_car
              @spots['large'].delete_at(idx)
              @spots['large'] << kar
              shuffled = true
              break
            elsif @spots['medium'].size < @capacity['medium']
              @spots['medium'] << parked_car
              @spots['large'].delete_at(idx)
              @spots['large'] << kar
              shuffled = true
              break
            end
          end
        end
        parked_at = 'large' if shuffled
      end
    end

    update_legacy_counters

    if parked_at
      "car with license plate no. #{plate} is parked at #{parked_at}"
    else
      "No space available"
    end
  end

  def exit_car(license_plate_no)
    plate = license_plate_no.to_s.strip
    removed = false

    ['small', 'medium', 'large'].each do |type|
      found = @spots[type].find { |car| car[:plate] == plate }
      if found
        @spots[type].delete(found)
        removed = true
        break
      end
    end

    update_legacy_counters

    if removed
      "car with license plate no. #{plate} exited"
    else
      "car with license plate no. #{plate} not found"
    end
  end

  def find_car(plate)
    ['small', 'medium', 'large'].each do |type|
      found = @spots[type].find { |car| car[:plate] == plate }
      return found if found
    end
    nil
  end

  def small
    @capacity['small'] - @spots['small'].size
  end

  def medium
    @capacity['medium'] - @spots['medium'].size
  end

  def large
    @capacity['large'] - @spots['large'].size
  end

  private

  def update_legacy_counters
    @small = small
    @medium = medium
    @large = large
  end
end

class ParkingTicket
  attr_accessor :entry_time
  attr_reader :id, :car_size, :license_plate, :license, :car_siez

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @license_plate = license_plate.to_s.strip
    @license = @license_plate
    @car_size = car_size.to_s.downcase.strip
    @car_siez = @car_size
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
    size = car_size.to_s.downcase.strip
    return 0.0 unless ['small', 'medium', 'large'].include?(size)

    duration = duration_hours.to_f rescue 0.0
    return 0.0 if duration < 0.0
    return 0.0 if duration <= 0.25

    hours = duration.ceil
    rate = RATES[size] || 0.0
    total = hours * rate
    max = MAX_FEE[size] || 0.0

    [total, max].min.to_f
  end
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :tix_in_flight

  def initialize(*args, **kwargs)
    if args.length >= 3
      small = args[0]
      medium = args[1]
      large = args[2]
    elsif kwargs.key?(:small_spots) || kwargs.key?(:medium_spots) || kwargs.key?(:large_spots)
      small = kwargs[:small_spots] || 0
      medium = kwargs[:medium_spots] || 0
      large = kwargs[:large_spots] || 0
    elsif kwargs.key?(:small) || kwargs.key?(:medium) || kwargs.key?(:large)
      small = kwargs[:small] || 0
      medium = kwargs[:medium] || 0
      large = kwargs[:large] || 0
    else
      small = args[0] || 0
      medium = args[1] || 0
      large = args[2] || 0
    end

    @garage = ParkingGarage.new(small, medium, large)
    @fee_calculator = ParkingFeeCalculator.new
    @tix_in_flight = {}
  end

  def admit_car(plate, size)
    clean_plate = plate.to_s.strip
    clean_size = size.to_s.downcase.strip

    if clean_plate.empty? || !['small', 'medium', 'large'].include?(clean_size)
      return { success: false, message: "No space available" }
    end

    verdict = @garage.admit_car(clean_plate, clean_size)

    if verdict.start_with?("car with license plate no.")
      ticket = ParkingTicket.new(clean_plate, clean_size)
      @tix_in_flight[clean_plate] = ticket
      { success: true, message: verdict, ticket: ticket }
    else
      { success: false, message: verdict }
    end
  end

  def exit_car(plate)
    clean_plate = plate.to_s.strip
    ticket = @tix_in_flight[clean_plate]

    unless ticket
      return { success: false, message: "car with license plate no. #{clean_plate} not found" }
    end

    duration = ticket.duration_hours
    fee = @fee_calculator.calculate_fee(ticket.car_size, duration)
    result = @garage.exit_car(clean_plate)

    @tix_in_flight.delete(clean_plate)

    { success: true, message: result, fee: fee, duration_hours: duration }
  end

  def garage_status
    s_avail = @garage.small
    m_avail = @garage.medium
    l_avail = @garage.large
    total_avail = s_avail + m_avail + l_avail
    total_spots = @garage.capacity['small'] + @garage.capacity['medium'] + @garage.capacity['large']
    total_occ = total_spots - total_avail

    {
      small_available: s_avail,
      medium_available: m_avail,
      large_available: l_avail,
      total_occupied: total_occ,
      total_available: total_avail,

      # Compatibility/Legacy keys
      small_open: s_avail,
      med_open: m_avail,
      lrg_open: l_avail,
      spots_left: total_avail,
      ticking: @tix_in_flight.size
    }
  end

  def find_ticket(plate)
    @tix_in_flight[plate.to_s.strip]
  end
end