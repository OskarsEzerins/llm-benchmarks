require 'date'

class Calendar
  MONTH_NAMES = %w[
    January February March April May June July August September October November December
  ].freeze

  WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : nil
  end

  def year
    @year
  end

  def is_leap_year?
    return false unless @year
    @year % 4 == 0 && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return nil unless @year
    days[month - 1] == 28 && month == 2 && is_leap_year? ? 29 : days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless valid_date?(month, day)
    "#{@year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil unless valid_date?(month, day)
    days_before = (1...month).sum { |m| days_in_month(m) }
    days_before + (day - 1)
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    return false unless @year
    dim = days_in_month(month)
    return false unless dim
    day.between?(1, dim)
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12) && @year
    dim = days_in_month(month)
    return [] unless dim
    (1..dim).map { |d| WEEKDAY_NAMES[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && target_day.is_a?(Integer)
    return 0 unless month.between?(1, 12) && target_day.between?(0, 6) && @year
    dim = days_in_month(month)
    return 0 unless dim
    (1..dim).count { |d| day_of_week(month, d) == target_day }
  end
end