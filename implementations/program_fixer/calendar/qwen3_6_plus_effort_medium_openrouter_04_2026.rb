class Calendar
  attr_reader :year

  def initialize(year)
    # Graceful handling: convert to integer, default to 0 if invalid/nil
    @year = year.to_i
  end

  def is_leap_year?
    # Fixed logic: divisible by 4 AND (not by 100 OR divisible by 400)
    # Fixed operator: && instead of bitwise &
    (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0)
  end

  def days_in_month(month)
    m = month.to_i
    # Handle invalid month inputs gracefully
    return 0 unless m.between?(1, 12)
    
    # Correct array for days in months (1-indexed with dummy 0)
    days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    
    # Check for leap year in February (month 2)
    if m == 2 && is_leap_year?
      29
    else
      days[m]
    end
  end

  def day_of_week(month, day)
    m = month.to_i
    d = day.to_i
    
    return nil unless m.between?(1, 12)
    
    # Sakamoto's algorithm to calculate day of week (0=Sunday, 6=Saturday)
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    y = year
    y -= 1 if m < 3
    
    (y + y/4 - y/100 + y/400 + t[m-1] + d) % 7
  end

  def get_month_name(month)
    m = month.to_i
    return nil unless m.between?(1, 12)
    # Fixed order of months and index offset
    %w[January February March April May June July August September October November December][m - 1]
  end

  def format_date(month, day)
    # Fixed format to YYYY-MM-DD with zero padding
    format("%04d-%02d-%02d", year, month.to_i, day.to_i)
  end

  def get_days_until_date(month, day)
    m = month.to_i
    d = day.to_i
    
    total = 0
    # Cap limit to avoid huge loops for invalid large months
    limit = m
    limit = 13 if limit > 13
    
    # Sum days of previous months
    (1...limit).each do |mon|
      total += days_in_month(mon)
    end
    
    # Add current days, subtract 1 (since Jan 1 is day 0 offset)
    total + d - 1
  end

  def is_valid_date?(month, day)
    m = month.to_i
    d = day.to_i
    
    # Fixed logic: month must be between 1 and 12 (OR condition)
    return false unless m.between?(1, 12)
    
    max_d = days_in_month(m)
    return false if max_d == 0
    
    # Fixed logic: day must be between 1 and max days (inclusive)
    d.between?(1, max_d)
  end

  def get_weekdays_in_month(month)
    m = month.to_i
    return [] unless m.between?(1, 12)
    
    weekdays = []
    # Fixed order: Sunday, Monday, ...
    day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    
    days = days_in_month(m)
    (1..days).each do |d|
      idx = day_of_week(m, d)
      weekdays << day_names[idx] if idx
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    m = month.to_i
    t = target_day.to_i
    
    return 0 unless m.between?(1, 12)
    
    count = 0
    days = days_in_month(m)
    (1..days).each do |d|
      # Fixed assignment (+=) and comparison (==)
      count += 1 if day_of_week(m, d) == t
    end
    count
  end
end