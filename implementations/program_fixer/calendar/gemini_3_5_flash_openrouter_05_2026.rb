require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    y = year.to_i rescue 0
    @year = y > 0 ? y : 2024
  end

  def is_leap_year?
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    days = [0, 31, is_leap_year? ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month]
  end

  def day_of_week(month, day)
    return 0 unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return "" unless month.is_a?(Integer) && month.between?(1, 12)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    m = month.to_i rescue 0
    d = day.to_i rescue 0
    sprintf("%04d-%02d-%02d", @year, m, d)
  end

  def get_days_until_date(month, day)
    return 0 unless is_valid_date?(month, day)
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
    return [] unless month.is_a?(Integer) && month.between?(1, 12)
    days_count = days_in_month(month)
    return [] if days_count == 0
    (1..days_count).map do |d|
      %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    days_count = days_in_month(month)
    return 0 if days_count == 0
    (1..days_count).count { |d| day_of_week(month, d) == target_day }
  end
end