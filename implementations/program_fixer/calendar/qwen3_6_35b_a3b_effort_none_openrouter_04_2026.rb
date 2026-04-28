class Calendar
  def initialize(year)
    return if year.nil?
    unless year.is_a?(Integer)
      return
    end
    if year < 0
      return
    end
    @year = year
  end

  def year
    @year
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer)
    return 0 if month < 1 || month > 12
    
    days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      return 29
    end
    days[month]
  end

  def day_of_week(month, day)
    return 0 unless month.is_a?(Integer) && day.is_a?(Integer)
    return 0 if month < 1 || month > 12 || day < 1
    
    total_days = get_days_until_date(month, day)
    # Jan 1, 2024 is Monday (1)
    # Jan 1, 0001 is Monday (1)
    # We need a reference. Let's use Zeller's or simply calculate from a known date.
    # Using the fact that Jan 1, 2024 is Monday (1).
    # Days from 2024-01-01 to the target date.
    # But simpler: use Ruby's Date if available, but we should implement manually.
    # Let's use the formula: Tomohiko Sakamoto's algorithm
    
    y = @year
    m = month
    d = day
    
    # Adjust for January and February
    if m < 3
      m += 12
      y -= 1
    end
    
    # Sakamoto's algorithm gives 0=Sunday, 1=Monday, ..., 6=Saturday
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4][m - 1]
    result = (y + y / 4 - y / 100 + y / 400 + t + d) % 7
    result
  end

  def get_month_name(month)
    return "Unknown" unless month.is_a?(Integer) && month >= 1 && month <= 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return "0000-00-00" unless @year && month.is_a?(Integer) && day.is_a?(Integer)
    if month < 1 || month > 12 || day < 1
      return "0000-00-00"
    end
    "#{@year.to_s.rjust(4, '0')}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return 0 unless month.is_a?(Integer) && day.is_a?(Integer)
    return 0 if month < 1 || month > 12 || day < 1
    
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1
    return false if day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    weekdays = []
    return weekdays unless month.is_a?(Integer) && month >= 1 && month <= 12
    
    num_days = days_in_month(month)
    (1..num_days).each do |d|
      dow = day_of_week(month, d)
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][dow]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    count = 0
    return count unless month.is_a?(Integer) && target_day.is_a?(Integer)
    return count if month < 1 || month > 12 || target_day < 0 || target_day > 6
    
    num_days = days_in_month(month)
    (1..num_days).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end