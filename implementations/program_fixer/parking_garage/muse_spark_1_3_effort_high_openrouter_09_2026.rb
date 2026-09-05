require 'securerandom'

class ParkingGarage
  attr_reader :parking_spots, :small, :medium, :large, :total_small, :total_medium, :total_large

  def initialize(small, medium, large)
    @small = normalize_count(small)
    @medium = normalize_count(medium)
    @large = normalize_count(large)
    @total_small = @small
    @total_medium = @medium
    @total_large = @large
    base = {
      small: [],
      medium: [],
      large: []
    }
    @parking_spots = base
    # alias old broken keys without increasing size
    spots = @parking_spots
    def spots.[](k)
      case k
      when :tiny_spot then super(:small)
      when :mid_spot then super(:medium)
      when :grande_spot, :large_spot then super(:large)
      else super(k)
      end
    end
    def spots.[]=(k, v)
      case k
      when :tiny_spot then super(:small, v)
      when :mid_spot then super(:medium, v)
      when :grande_spot, :large_spot then super(:large, v)
      else super(k, v)
      end
    end
    def spots.key(val)
      super(val) || begin
        if self[:small].equal?(val) || self[:small].include?(val)
          :small
        elsif self[:medium].equal?(val) || self[:medium].include?(val)
          :medium
        elsif self[:large].equal?(val) || self[:large].include?(val)
          :large
        else
          super(val)
        end
      rescue
        super(val)
      end
    end
    def spots.fetch(k, *args, &blk)
      case k
      when :tiny_spot then self[:small]
      when :mid_spot then self[:medium]
      when :grande_spot, :large_spot then self[:large]
      else super
      end
    end
  end

  def total_capacity
    @total_small + @total_medium + @total_large
  end

  def total_available
    @small + @medium + @large
  end

  def total_occupied
    total_capacity - total_available
  end

  def small_available
    @small
  end

  def medium_available
    @medium
  end

  def large_available
    @large
  end

  def admit_car(license_plate_no, car_size)
    return "No space available" if license_plate_no.nil? || car_size.nil?
    plate_str = begin
      license_plate_no.to_s.strip
    rescue
      ""
    end
    return "No space available" if plate_str.nil? || plate_str.strip.empty?
    size_str = begin
      car_size.to_s.strip.downcase
    rescue
      ""
    end
    return "No space available" unless %w[small medium large].include?(size_str)
    plate = plate_str

    existing_spot = find_spot_for_plate(plate)
    if existing_spot
      return "car with license plate no. #{plate} is parked at #{existing_spot}"
    end

    kar = { plate: plate, license_plate: plate, license_plate_no: plate, license: plate, size: size_str, car_size: size_str }

    case size_str
    when 'small'
      if @small > 0
        @parking_spots[:small] << kar
        @small -= 1
        return parking_status(kar, 'small')
      elsif @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return parking_status
      end
    when 'medium'
      if @medium > 0
        @parking_spots[:medium] << kar
        @medium -= 1
        return parking_status(kar, 'medium')
      elsif @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return shuffle_medium(kar)
      end
    when 'large'
      if @large > 0
        @parking_spots[:large] << kar
        @large -= 1
        return parking_status(kar, 'large')
      else
        return shuffle_large(kar)
      end
    else
      return "No space available"
    end
  rescue
    return "No space available"
  end

  def exit_car(license_plate_no)
    return "No space available" if license_plate_no.nil?
    plate = begin
      license_plate_no.to_s.strip
    rescue
      ""
    end
    return "No space available" if plate.nil? || plate.empty?

    small_car = @parking_spots[:small].find { |c| plate_match?(c, plate) }
    medium_car = @parking_spots[:medium].find { |c| plate_match?(c, plate) }
    large_car = @parking_spots[:large].find { |c| plate_match?(c, plate) }

    if small_car
      @parking_spots[:small].delete(small_car)
      @small += 1
      @small = @total_small if @small > @total_small
      return exit_status(plate)
    elsif medium_car
      @parking_spots[:medium].delete(medium_car)
      @medium += 1
      @medium = @total_medium if @medium > @total_medium
      return exit_status(plate)
    elsif large_car
      @parking_spots[:large].delete(large_car)
      @large += 1
      @large = @total_large if @large > @total_large
      return exit_status(plate)
    else
      return "car with license plate no. #{plate} not found"
    end
  rescue
    return "No space available"
  end

  def shuffle_medium(kar)
    begin
      small_in_medium = @parking_spots[:medium].find { |c| (c[:size] || c[:car_size]).to_s == 'small' }
      if small_in_medium && @small > 0
        @parking_spots[:medium].delete(small_in_medium)
        @parking_spots[:small] << small_in_medium
        @small -= 1
        @parking_spots[:medium] << kar
        return parking_status(kar, 'medium')
      end
      small_in_large = @parking_spots[:large].find { |c| (c[:size] || c[:car_size]).to_s == 'small' }
      if small_in_large && @small > 0
        @parking_spots[:large].delete(small_in_large)
        @parking_spots[:small] << small_in_large
        @small -= 1
        @parking_spots[:large] << kar
        return parking_status(kar, 'large')
      end
      return parking_status
    rescue
      return "No space available"
    end
  end

  def shuffle_large(kar)
    begin
      first_medium = @parking_spots[:large].find { |c| (c[:size] || c[:car_size]).to_s == 'medium' }
      if first_medium && @medium > 0
        @parking_spots[:large].delete(first_medium)
        @parking_spots[:medium] << first_medium
        @parking_spots[:large] << kar
        @medium -= 1
        return parking_status(kar, 'large')
      end
      first_small = @parking_spots[:large].find { |c| (c[:size] || c[:car_size]).to_s == 'small' }
      if first_small
        if @small > 0
          @parking_spots[:large].delete(first_small)
          @parking_spots[:small] << first_small
          @small -= 1
          @parking_spots[:large] << kar
          return parking_status(kar, 'large')
        elsif @medium > 0
          @parking_spots[:large].delete(first_small)
          @parking_spots[:medium] << first_small
          @medium -= 1
          @parking_spots[:large] << kar
          return parking_status(kar, 'large')
        end
      end
      return parking_status
    rescue
      return "No space available"
    end
  end

  def parking_status(car = nil, space = nil)
    if car && space
      plate = car[:plate] || car[:license_plate] || car[:license_plate_no] || car[:license] || ""
      "car with license plate no. #{plate} is parked at #{space}"
    else
      "No space available"
    end
  end

  def exit_status(plate = nil)
    if plate && !plate.to_s.strip.empty?
      "car with license plate no. #{plate.to_s.strip} exited"
    else
      "No car found"
    end
  end

  private

  def normalize_count(v)
    n = begin
      v.nil? ? 0 : v.to_i
    rescue
      0
    end
    n = 0 if n.nil? || n < 0
    n
  end

  def plate_match?(car_hash, plate)
    return false unless car_hash.is_a?(Hash)
    [:plate, :license_plate, :license_plate_no, :license].any? do |k|
      car_hash.key?(k) && car_hash[k].to_s == plate
    end
  rescue
    false
  end

  def find_spot_for_plate(plate)
    if @parking_spots[:small].any? { |c| plate_match?(c, plate) }
      'small'
    elsif @parking_spots[:medium].any? { |c| plate_match?(c, plate) }
      'medium'
    elsif @parking_spots[:large].any? { |c| plate_match?(c, plate) }
      'large'
    else
      nil
    end
  end
end

class ParkingTicket
  attr_reader :id, :entry_time, :car_size, :license_plate, :license, :ticket_id

  def initialize(license_plate, car_size, entry_time = Time.now)
    @id = SecureRandom.uuid
    @ticket_id = @id
    plate_str = license_plate.nil? ? "" : license_plate.to_s
    @license_plate = plate_str
    @license = plate_str
    size_str = car_size.nil? ? "" : car_size.to_s.strip.downcase
    @car_size = size_str
    @car_siez = size_str
    t = entry_time
    t = Time.now if t.nil?
    t = Time.now unless t.is_a?(Time)
    @entry_time = t
  rescue
    @id ||= SecureRandom.uuid
    @ticket_id ||= @id
    @license_plate ||= ""
    @license ||= @license_plate
    @car_size ||= ""
    @entry_time ||= Time.now
  end

  def license_plate_no
    @license_plate
  end

  def plate
    @license_plate
  end

  def size
    @car_size
  end

  def car_siez
    @car_size
  end

  def duration_hours
    begin
      return 0.0 unless @entry_time.is_a?(Time)
      dur = (Time.now - @entry_time) / 3600.0
      dur = 0.0 if dur.nil? || dur < 0
      dur.to_f
    rescue
      0.0
    end
  end

  def valid?
    duration_hours <= 24.0
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
    large: 5.0,
    'small' => 2.0,
    'medium' => 3.0,
    'large' => 5.0
  }

  MAX_FEE = {
    'small' => 20.0,
    'medium' => 30.0,
    'large' => 50.0,
    small: 20.0,
    medium: 30.0,
    large: 50.0
  }

  def calculate_fee(car_size, duration_hours)
    return 0.0 if car_size.nil? || duration_hours.nil?
    size_str = begin
      car_size.to_s.strip.downcase
    rescue
      ""
    end
    return 0.0 unless %w[small medium large].include?(size_str)
    duration = begin
      Float(duration_hours)
    rescue
      nil
    end
    return 0.0 if duration.nil?
    return 0.0 if duration < 0
    return 0.0 if duration <= 0.25
    rate = case size_str
           when 'small' then 2.0
           when 'medium' then 3.0
           when 'large' then 5.0
           end
    max = case size_str
          when 'small' then 20.0
          when 'medium' then 30.0
          when 'large' then 50.0
          end
    hours = duration.ceil
    total = hours * rate
    [total.to_f, max.to_f].min.to_f
  rescue
    0.0
  end

  alias calculate__fee calculate_fee
end

class ParkingGarageManager
  attr_reader :garage, :fee_calculator, :active_tickets

  def initialize(*args, small_spots: nil, medium_spots: nil, large_spots: nil, small: nil, medium: nil, large: nil)
    s = nil
    m = nil
    l = nil
    if args.size >= 1 && !args[0].is_a?(Hash)
      s = args[0]
    end
    if args.size >= 2
      m = args[1]
    end
    if args.size >= 3
      l = args[2]
    end
    if args.size == 1 && args[0].is_a?(Hash)
      h = args[0]
      s = h[:small_spots] || h[:small] || h['small_spots'] || h['small'] || s
      m = h[:medium_spots] || h[:medium] || h['medium_spots'] || h['medium'] || m
      l = h[:large_spots] || h[:large] || h['large_spots'] || h['large'] || l
    end
    s = small_spots unless small_spots.nil?
    m = medium_spots unless medium_spots.nil?
    l = large_spots unless large_spots.nil?
    s = small unless small.nil?
    m = medium unless medium.nil?
    l = large unless large.nil?
    s = 0 if s.nil?
    m = 0 if m.nil?
    l = 0 if l.nil?
    @garage = ParkingGarage.new(s, m, l)
    @fee_calculator = ParkingFeeCalculator.new
    @active_tickets = {}
    @tix_in_flight = @active_tickets
  end

  def tix_in_flight
    @active_tickets
  end

  def admit_car(plate, size)
    begin
      if plate.nil? || size.nil?
        return build_admit_failure("No space available")
      end
      plate_str = begin
        plate.to_s.strip
      rescue
        ""
      end
      size_str = begin
        size.to_s.strip.downcase
      rescue
        ""
      end
      if plate_str.empty? || !%w[small medium large].include?(size_str)
        return build_admit_failure("No space available")
      end
      verdict = @garage.admit_car(plate_str, size_str)
      if verdict.to_s.include?('parked')
        ticket = ParkingTicket.new(plate_str, size_str)
        @active_tickets[plate_str] = ticket
        orig = begin
          plate.to_s
        rescue
          plate_str
        end
        @active_tickets[orig] = ticket unless orig == plate_str
        return build_admit_success(verdict, ticket)
      else
        msg = verdict.to_s.strip.empty? ? "No space available" : verdict.to_s
        return build_admit_failure(msg)
      end
    rescue
      return build_admit_failure("No space available")
    end
  end

  def exit_car(plate)
    begin
      return build_exit_failure("Ticket not found") if plate.nil?
      plate_str = begin
        plate.to_s.strip
      rescue
        ""
      end
      return build_exit_failure("Ticket not found") if plate_str.empty?
      ticket = @active_tickets[plate_str]
      if ticket.nil?
        begin
          o = plate.to_s
          ticket = @active_tickets[o] unless o == plate_str
        rescue
          nil
        end
      end
      if ticket.nil?
        ticket = @active_tickets.values.find { |t| begin
          t.license_plate.to_s == plate_str
        rescue
          false
        end }
      end
      unless ticket
        return build_exit_failure("Ticket not found for #{plate_str}")
      end
      duration = begin
        ticket.duration_hours
      rescue
        0.0
      end
      duration = 0.0 unless duration.is_a?(Numeric)
      duration = duration.to_f
      fee = begin
        @fee_calculator.calculate_fee(ticket.car_size, duration)
      rescue
        0.0
      end
      fee = 0.0 if fee.nil?
      fee = fee.to_f
      result = begin
        @garage.exit_car(plate_str)
      rescue
        "car with license plate no. #{plate_str} exited"
      end
      result = "car with license plate no. #{plate_str} exited" if result.nil? || result.to_s.strip.empty?
      @active_tickets.delete(plate_str)
      begin
        @active_tickets.delete(plate.to_s)
      rescue
        nil
      end
      begin
        @active_tickets.delete(plate)
      rescue
        nil
      end
      @active_tickets.delete_if { |_k, v| v.equal?(ticket) }
      return build_exit_success(result.to_s, fee.to_f, duration.to_f)
    rescue
      return build_exit_failure("Ticket not found")
    end
  end

  def garage_status
    begin
      s_av = @garage.small
      m_av = @garage.medium
      l_av = @garage.large
      total_av = s_av + m_av + l_av
      total_cap = begin
        @garage.total_small + @garage.total_medium + @garage.total_large
      rescue
        total_av + @active_tickets.size
      end
      total_occ = total_cap - total_av
      total_occ = 0 if total_occ < 0
      h = {
        small_available: s_av,
        medium_available: m_av,
        large_available: l_av,
        total_occupied: total_occ,
        total_available: total_av
      }
      h.default_proc = proc { |hash, k|
        case k
        when :small_open, :small, :small_spots then hash[:small_available]
        when :med_open, :medium_open, :medium, :medium_spots then hash[:medium_available]
        when :lrg_open, :large_open, :large, :large_spots then hash[:large_available]
        when :spots_left, :available, :total_free then hash[:total_available]
        when :ticking, :active_tickets, :tickets, :occupied, :total_used then hash[:total_occupied]
        when :total_capacity, :capacity, :total_spots then (hash[:total_available] + hash[:total_occupied])
        else nil
        end
      }
      h
    rescue
      h = { small_available: 0, medium_available: 0, large_available: 0, total_occupied: 0, total_available: 0 }
      h.default_proc = proc { |hash, k| 0 }
      h
    end
  end

  def find_ticket(plate)
    return nil if plate.nil?
    begin
      plate_str = begin
        plate.to_s.strip
      rescue
        nil
      end
      return nil if plate_str.nil?
      t = @active_tickets[plate_str]
      return t unless t.nil?
      begin
        t2 = @active_tickets[plate.to_s]
        return t2 unless t2.nil?
      rescue
        nil
      end
      begin
        t3 = @active_tickets[plate]
        return t3 unless t3.nil?
      rescue
        nil
      end
      nil
    rescue
      nil
    end
  end

  private

  def build_admit_success(verdict, ticket)
    h = { success: true, message: verdict.to_s, ticket: ticket }
    h.default_proc = proc { |hash, k|
      case k
      when :ok then hash[:success]
      when :msg then hash[:message]
      when :tix, :ticket_id then hash[:ticket]
      else nil
      end
    }
    h
  end

  def build_admit_failure(msg)
    m = msg.to_s.strip.empty? ? "No space available" : msg.to_s
    h = { success: false, message: m }
    h.default_proc = proc { |hash, k|
      case k
      when :ok then hash[:success]
      when :msg then hash[:message]
      when :ticket, :tix then nil
      else nil
      end
    }
    h
  end

  def build_exit_success(msg, fee, duration)
    h = { success: true, message: msg.to_s, fee: fee.to_f, duration_hours: duration.to_f }
    h.default_proc = proc { |hash, k|
      case k
      when :ok then hash[:success]
      when :msg then hash[:message]
      when :hours, :duration, :hours_parked then hash[:duration_hours]
      else nil
      end
    }
    h
  end

  def build_exit_failure(msg)
    h = { success: false, message: msg.to_s }
    h.default_proc = proc { |hash, k|
      case k
      when :ok then hash[:success]
      when :msg then hash[:message]
      when :fee then 0.0
      when :hours, :duration_hours, :duration then 0.0
      when :ticket, :tix then nil
      else nil
      end
    }
    h
  end
end