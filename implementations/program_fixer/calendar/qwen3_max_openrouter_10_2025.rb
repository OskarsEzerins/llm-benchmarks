class Calendar
  def initialize(year)
    @year = if year.is_a?(Integer) && year > 0
              year
            else
              nil
            end
  end

  def year
    @year
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
    return nil if !is_valid_date?(month, day)
    
    total_days = 0
    (1...month).each { |m| total_days += days_in_month(m) }
    total_days += day - 1
    
    # January 1, 0001 was a Monday, but we need to calculate from a known reference
    # Using known fact: January 1, 1900 was a Monday (but 1900 is not leap year)
    # However, easier approach: use known algorithm for day of week
    # Zeller's congruence variant or just calculate from epoch
    
    # For simplicity, use the fact that we know Jan 1, 2024 is Monday (1)
    # But better to use a general algorithm
    
    # Using the formula: (reference + total days) % 7
    # We know that Jan 1, 0001 would be day 1 (Monday) if we calculate properly
    # Actually, let's use a known reference: Jan 1, 1970 was Thursday (4)
    # But our year might be before 1970
    
    # Alternative: use the fact that we can calculate based on known leap years
    # Simpler: calculate total days since year 1, then mod 7
    
    # Calculate total days from year 1 to our date
    total_years_days = 0
    (1...@year).each do |y|
      total_years_days += 365
      total_years_days += 1 if (y % 4).zero? && ((y % 100).nonzero? || (y % 400).zero?)
    end
    
    day_number = total_years_days + total_days
    # Jan 1, year 1 was a Saturday (according to proleptic Gregorian calendar)
    # Actually, in proleptic Gregorian, Jan 1, 1 AD was a Saturday (6)
    # So: (6 + day_number) % 7
    (6 + day_number) % 7
  end

  def get_month_name(month)
    return nil if !month.is_a?(Integer) || month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil if !is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil if !is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if @year.nil?
    return false if !month.is_a?(Integer) || !day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] if @year.nil? || !month.is_a?(Integer) || month < 1 || month > 12
    weekdays = []
    (1..days_in_month(month)).each do |d|
      day_index = day_of_week(month, d)
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_index]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if @year.nil? || !month.is_a?(Integer) || month < 1 || month > 12 || !target_day.is_a?(Integer) || target_day < 0 || target_day > 6
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end