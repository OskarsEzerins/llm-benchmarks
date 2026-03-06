require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : 0
  end

  def is_leap_year?
    return false unless @year > 0
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)

    case month
    when 1,3,5,7,8,10,12
      31
    when 4,6,9,11
      30
    when 2
      is_leap_year? ? 29 : 28
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    months = %w[January February March April May June July August September October November December]
    return nil unless month.is_a?(Integer) && month.between?(1,12)
    months[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    (Date.new(@year, month, day) - Date.new(@year, 1, 1)).to_i
  end

  def is_valid_date?(month, day)
    return false unless @year > 0
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    Date.valid_date?(@year, month, day)
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1,12)

    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    days = days_in_month(month)
    return [] unless days

    weekdays = []
    (1..days).each do |d|
      w = day_of_week(month, d)
      weekdays << names[w] if w
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month.between?(1,12)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0,6)

    count = 0
    days = days_in_month(month)
    return 0 unless days

    (1..days).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end