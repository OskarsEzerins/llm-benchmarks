require 'date'

class Calendar
  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = nil
    end
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4 == 0) && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    days = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      29
    else
      days[month]
    end
  end

  def day_of_week(month, day)
    return nil unless @year && month.is_a?(Integer) && day.is_a?(Integer) && is_valid_date?(month, day)
    Date.new(@year, month, day).wday  # 0 = Sunday, 6 = Saturday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless @year && month.is_a?(Integer) && day.is_a?(Integer) && is_valid_date?(month, day)
    "#{@year}-#{'%02d' % month}-#{'%02d' % day}"
  end

  def get_days_until_date(month, day)
    return nil unless @year && month.is_a?(Integer) && day.is_a?(Integer) && is_valid_date?(month, day)
    total = 0
    1.upto(month - 1) { |m| total += days_in_month(m) || 0 }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    max_days = days_in_month(month)
    return false unless max_days && day.between?(1, max_days)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)
    weekdays = []
    1.upto(days_in_month(month) || 0) do |d|
      if is_valid_date?(month, d)
        wday = day_of_week(month, d)
        weekdays << %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][wday] if wday
      end
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12) && target_day.is_a?(Integer) && target_day.between?(0, 6)
    count = 0
    1.upto(days_in_month(month) || 0) do |d|
      if is_valid_date?(month, d) && day_of_week(month, d) == target_day
        count += 1
      end
    end
    count
  end
end