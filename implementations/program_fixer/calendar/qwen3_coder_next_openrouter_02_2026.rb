class Calendar
  def initialize(year)
    @year = if year.is_a?(Integer) && year > 0
              year
            else
              raise ArgumentError, "Invalid year"
            end
  rescue ArgumentError
    @year = nil
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil if @year.nil? || !month.is_a?(Integer) || month < 1 || month > 12
    
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1] + (month == 2 && is_leap_year? ? 1 : 0)
  end

  def day_of_week(month, day)
    return nil if @year.nil? || !is_valid_date?(month, day)
    
    # Use Zeller's congruence adapted for 0=Sunday
    m = month
    y = @year
    if m < 3
      m += 12
      y -= 1
    end
    
    q = day
    k = y % 100
    j = y / 100
    
    h = (q + (13 * (m + 1)) / 5 + k + k / 4 + j / 4 - 2 * j) % 7
    # Convert from Zeller (0=Saturday) to our format (0=Sunday)
    ((h + 6) % 7).to_i
  end

  def get_month_name(month)
    return nil if month < 1 || month > 12
    
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil if !is_valid_date?(month, day)
    
    "#{@year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil if !is_valid_date?(month, day)
    
    days = 0
    (1...month).each do |m|
      days += days_in_month(m)
    end
    days + day - 1
  end

  def is_valid_date?(month, day)
    return false if @year.nil? || 
                   !month.is_a?(Integer) || 
                   !day.is_a?(Integer) || 
                   month < 1 || 
                   month > 12 || 
                   day < 1
    
    max_days = days_in_month(month)
    max_days && day <= max_days
  end

  def get_weekdays_in_month(month)
    return [] if @year.nil? || month < 1 || month > 12
    
    weekdays = []
    days_in_month(month).times do |i|
      day = i + 1
      dow = day_of_week(month, day)
      next if dow.nil?
      weekdays << %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][dow]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if @year.nil? || month < 1 || month > 12 || 
                !target_day.is_a?(Integer) || target_day < 0 || target_day > 6
    
    count = 0
    days_in_month(month).times do |i|
      day = i + 1
      dow = day_of_week(month, day)
      count += 1 if dow == target_day
    end
    count
  end
end