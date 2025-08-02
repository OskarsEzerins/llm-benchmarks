require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : nil
  end

  def is_leap_year?
    return false unless @year
    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless @year && month.is_a?(Integer) && month.between?(1, 12)
    case month
    when 1, 3, 5, 7, 8, 10, 12 then 31
    when 4, 6, 9, 11 then 30
    when 2 then is_leap_year? ? 29 : 28
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    Date::MONTHNAMES[month]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    day_of_year = (1...month).sum { |m| days_in_month(m) } + day
    day_of_year - 1
  end

  def is_valid_date?(month, day)
    return false unless @year.is_a?(Integer) && @year > 0
    return false unless month.is_a?(Integer) && month.between?(1, 12)
    dim = days_in_month(month)
    return false unless day.is_a?(Integer) && day.between?(1, dim)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)
    (1..days_in_month(month)).map { |d| Date::DAYNAMES[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    (1..days_in_month(month)).count { |d| day_of_week(month, d) == target_day }
  end
end