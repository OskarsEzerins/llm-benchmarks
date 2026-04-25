class Calendar
  attr_reader :year

  def initialize(year)
    if year.nil? || !year.is_a?(Integer) || year < 1
      @year = 1
    else
      @year = year
    end
  end

  def is_leap_year?
    (@year % 4).zero? && (@year % 100 != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil if month.nil? || !month.is_a?(Integer)
    return nil if month < 1 || month > 12
    
    days_in_months = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days_in_months[2] = 29 if is_leap_year?
    days_in_months[month]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    
    # Using Zeller's congruence adapted for Ruby
    m = month
    y = @year
    if m < 3
      m += 12
      y -= 1
    end
    k = y % 100
    j = y / 100
    f = day + ((13 * (m + 1)) / 5) + k + (k / 4) + (j / 4) - (2 * j)
    result = f % 7
    result = (result + 7) % 7
    # Convert to 0=Sunday, 6=Saturday
    (result + 6) % 7
  end

  def get_month_name(month)
    return nil if month.nil? || !month.is_a?(Integer)
    return nil if month < 1 || month > 12
    
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "#{@year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if month.nil? || !month.is_a?(Integer)
    return false if day.nil? || !day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] if month.nil? || !month.is_a?(Integer) || month < 1 || month > 12
    
    weekdays = []
    (1..days_in_month(month)).each do |d|
      dow = day_of_week(month, d)
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][dow]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if month.nil? || !month.is_a?(Integer) || month < 1 || month > 12
    return 0 if target_day.nil? || !target_day.is_a?(Integer)
    return 0 if target_day < 0 || target_day > 6
    
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end