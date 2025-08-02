class Calendar
  attr_reader :year
  
  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : 2000
  end

  def is_leap_year?
    return false unless @year
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return days[month-1] + (month == 2 && is_leap_year? ? 1 : 0)
  end

  def day_of_week(month, day)
    return 0 unless is_valid_date?(month, day)
    
    m = month
    y = @year
    if m < 3
      m += 12
      y -= 1
    end
    
    h = (day + (13 * (m + 1)) / 5 + y + y / 4 - y / 100 + y / 400) % 7
    (h + 6) % 7  # Adjust to make Sunday=0
  end

  def get_month_name(month)
    return "" unless month.is_a?(Integer) && month >= 1 && month <= 12
    
    %w[January February March April May June July August September October November December][month-1]
  end

  def format_date(month, day)
    return "" unless is_valid_date?(month, day)
    
    "#{@year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return 0 unless is_valid_date?(month, day)
    
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1  # Subtract 1 because we don't count Jan 1
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