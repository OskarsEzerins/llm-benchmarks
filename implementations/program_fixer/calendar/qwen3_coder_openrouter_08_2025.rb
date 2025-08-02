class Calendar
  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = Time.now.year
    end
  end

  attr_reader :year

  def is_leap_year?
    (year % 4).zero? && ((year % 100).nonzero? || (year % 400).zero?)
  end

  def days_in_month(month)
    return nil if month.nil? || month < 1 || month > 12
    
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return days[month - 1] unless month == 2 && is_leap_year?
    29
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    
    # Using Zeller's congruence algorithm
    m = month
    y = year
    d = day
    
    if m < 3
      m += 12
      y -= 1
    end
    
    k = y % 100
    j = y / 100
    
    h = (d + ((13 * (m + 1)) / 5).floor + k + (k / 4).floor + (j / 4).floor - 2 * j) % 7
    
    # Convert to Sunday=0 format
    (h + 5) % 7
  end

  def get_month_name(month)
    return nil if month.nil? || month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer) && month >= 1 && month <= 12 && day >= 1
    sprintf("%04d-%02d-%02d", year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day
  end

  def is_valid_date?(month, day)
    return false if month.nil? || day.nil? || !month.is_a?(Integer) || !day.is_a?(Integer)
    return false if month < 1 || month > 12 || day < 1
    day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    
    weekdays = []
    day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).each do |d|
      weekdays << day_names[day_of_week(month, d)]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && target_day.is_a?(Integer) && month >= 1 && month <= 12 && target_day >= 0 && target_day <= 6
    
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end