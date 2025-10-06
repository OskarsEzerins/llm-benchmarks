class Calendar
  def initialize(year)
    @year = if year.is_a?(Integer) && year > 0
              year
            else
              1
            end
  end

  def year
    @year
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      29
    else
      days[month - 1]
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    
    total_days = 0
    (1...month).each { |m| total_days += days_in_month(m) }
    total_days += day - 1
    
    # January 1, 0001 was a Monday (but we need to calculate based on known reference)
    # Using Zeller's congruence or calculating from known reference
    # For simplicity, we'll use the fact that we can calculate days from a reference
    # Let's use 0001-01-01 as Monday (which is day 1), so we need offset
    # Actually, let's use a simpler approach: calculate total days since epoch
    # But since we only care about the year, we can calculate from Jan 1 of our year
    
    # First, find what day Jan 1 is
    # We'll use the known fact that 2024-01-01 is Monday (1)
    # But we need a general formula. Let's use the standard approach:
    
    # Using Tomohiko Sakamoto's algorithm
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    y = @year - (month < 3 ? 1 : 0)
    (y + y/4 - y/100 + y/400 + t[month-1] + day) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1
    days_in_current_month = days_in_month(month)
    return false if days_in_current_month.nil? || day > days_in_current_month
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    
    weekdays = []
    month_days = days_in_month(month)
    return [] if month_days.nil?
    
    (1..month_days).each do |d|
      dow = day_of_week(month, d)
      next if dow.nil?
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][dow]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && target_day.is_a?(Integer)
    return 0 unless month >= 1 && month <= 12
    return 0 unless target_day >= 0 && target_day <= 6
    
    count = 0
    month_days = days_in_month(month)
    return 0 if month_days.nil?
    
    (1..month_days).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end