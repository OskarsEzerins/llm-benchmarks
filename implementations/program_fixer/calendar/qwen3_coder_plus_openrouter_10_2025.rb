class Calendar
  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : 1
  end

  attr_reader :year

  def is_leap_year?
    (year % 4).zero? && ((year % 100).nonzero? || (year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    result = days[month - 1]
    result += 1 if month == 2 && is_leap_year?
    result
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    
    # Using Zeller's congruence algorithm
    m, y = month, year
    if m < 3
      m += 12
      y -= 1
    end
    
    k = y % 100
    j = y / 100
    
    h = (day + ((13 * (m + 1)) / 5).floor + k + (k / 4).floor + (j / 4).floor - 2 * j) % 7
    (h + 5) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer) && month >= 1 && month <= 12 && day >= 1 && day <= 31
    
    sprintf("%04d-%02d-%02d", year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6
    
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end