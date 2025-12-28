class Calendar
  def initialize(year)
    @year = year.to_i
    return if @year > 0
    @year = 1
  end

  def year
    @year
  end

  def is_leap_year?
    return false if @year < 1
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Numeric)
    month = month.to_i
    return nil unless month >= 1 && month <= 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      return 29
    end
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless month.is_a?(Numeric) && day.is_a?(Numeric)
    month = month.to_i
    day = day.to_i
    return nil unless month >= 1 && month <= 12
    return nil unless day >= 1 && day <= (days_in_month(month) || 0)
    
    y = @year
    m = month
    d = day
    if m < 3
      m += 12
      y -= 1
    end
    (d + (2 * m) + (3 * (m + 1) / 5) + y + (y / 4) - (y / 100) + (y / 400) + 2) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Numeric)
    month = month.to_i
    return nil unless month >= 1 && month <= 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless month.is_a?(Numeric) && day.is_a?(Numeric)
    month = month.to_i
    day = day.to_i
    return nil unless month >= 1 && month <= 12
    return nil unless day >= 1 && day <= (days_in_month(month) || 0)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless month.is_a?(Numeric) && day.is_a?(Numeric)
    month = month.to_i
    day = day.to_i
    return nil unless month >= 1 && month <= 12
    return nil unless day >= 1 && day <= (days_in_month(month) || 0)
    
    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Numeric) && day.is_a?(Numeric)
    month = month.to_i
    day = day.to_i
    return false unless month >= 1 && month <= 12
    max_days = days_in_month(month)
    return false unless max_days
    day >= 1 && day <= max_days
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Numeric)
    month = month.to_i
    return [] unless month >= 1 && month <= 12
    weekdays = []
    (1..(days_in_month(month) || 0)).each do |d|
      dow = day_of_week(month, d)
      weekdays << %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][dow]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Numeric) && target_day.is_a?(Numeric)
    month = month.to_i
    target_day = target_day.to_i
    return 0 unless month >= 1 && month <= 12
    return 0 unless target_day >= 0 && target_day <= 6
    count = 0
    (1..(days_in_month(month) || 0)).each do |d|
      if day_of_week(month, d) == target_day
        count += 1
      end
    end
    count
  end
end