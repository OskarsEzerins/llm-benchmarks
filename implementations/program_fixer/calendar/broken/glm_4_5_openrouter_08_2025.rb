class Calendar
  def initialize(year)
    # Handle invalid years
    if year.nil? || year.to_s !~ /^-?\d+$/ || year.to_i <= 0
      @year = 2024  # Default year
    else
      @year = year.to_i
    end
  end

  def is_leap_year?
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    # Handle invalid month
    return nil if month.nil? || month.to_i < 1 || month.to_i > 12
    month = month.to_i
    
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    # Handle invalid inputs
    return nil if month.nil? || day.nil? || !is_valid_date?(month.to_i, day.to_i)
    month = month.to_i
    day = day.to_i
    
    # Using Zeller's Congruence algorithm
    if month < 3
      m = month + 12
      year = @year - 1
    else
      m = month
      year = @year
    end
    
    K = year % 100
    J = year / 100
    
    h = (day + (13 * (m + 1)) / 5 + K + K / 4 + J / 4 + 5 * J) % 7
    
    # Convert to 0=Sunday, 6=Saturday format
    (h + 6) % 7
  end

  def get_month_name(month)
    # Handle invalid month
    return nil if month.nil? || month.to_i < 1 || month.to_i > 12
    month = month.to_i
    
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    # Handle invalid inputs
    return nil if month.nil? || day.nil? || !is_valid_date?(month.to_i, day.to_i)
    month = month.to_i
    day = day.to_i
    
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    # Handle invalid inputs
    return nil if month.nil? || day.nil? || !is_valid_date?(month.to_i, day.to_i)
    month = month.to_i
    day = day.to_i
    
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day
  end

  def is_valid_date?(month, day)
    # Handle nil inputs
    return false if month.nil? || day.nil?
    
    month = month.to_i
    day = day.to_i
    
    # Check month range
    return false if month < 1 || month > 12
    
    # Check day range
    max_days = days_in_month(month)
    return false if day < 1 || day > max_days
    
    true
  end

  def get_weekdays_in_month(month)
    # Handle invalid month
    return [] if month.nil? || month.to_i < 1 || month.to_i > 12
    month = month.to_i
    
    weekdays = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    result = []
    (1..days_in_month(month)).each do |d|
      day_idx = day_of_week(month, d)
      result << weekdays[day_idx] if day_idx
    end
    result
  end

  def count_occurrences_of_day(month, target_day)
    # Handle invalid inputs
    return 0 if month.nil? || target_day.nil? || month.to_i < 1 || month.to_i > 12 || target_day.to_i < 0 || target_day.to_i > 6
    month = month.to_i
    target_day = target_day.to_i
    
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end