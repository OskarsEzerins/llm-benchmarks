class Calendar
  attr_reader :year
  
  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = Time.now.year
    end
  end

  def is_leap_year?
    (year % 4).zero? && ((year % 100).nonzero? || (year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if is_leap_year? && month == 2
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    
    if month < 3
      m = month + 12
      y = year - 1
    else
      m = month
      y = year
    end
    
    h = (day + (26 * (m + 1)) / 10 + y % 100 + (y % 100) / 4 + (y / 100) / 4 + 5 * (y / 100)) % 7
    
    (h + 6) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    
    format("%04d-%02d-%02d", year, month, day)
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
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12 && 
                    target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6
    
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end