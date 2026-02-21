require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.to_i
  end

  def is_leap_year?
    (@year % 400 == 0) || (@year % 4 == 0 && @year % 100 != 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    month == 2 && is_leap_year? ? 29 : days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = (1...month).reduce(0) { |sum, m| sum + days_in_month(m) } + day
    total - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    days = days_in_month(month)
    return false if days.nil?
    day.between?(1, days)
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)
    days = days_in_month(month)
    return [] if days.nil?
    (1..days).map do |d|
      idx = day_of_week(month, d)
      %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][idx]
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12) &&
                    target_day.is_a?(Integer) && target_day.between?(0, 6)
    days = days_in_month(month)
    return 0 if days.nil?
    (1..days).count { |d| day_of_week(month, d) == target_day }
  end
end