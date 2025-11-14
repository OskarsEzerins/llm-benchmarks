require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : 0
  end

  def is_leap_year?
    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && (1..12).include?(month)

    case month
    when 1, 3, 5, 7, 8, 10, 12
      31
    when 4, 6, 9, 11
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
    return nil unless month.is_a?(Integer) && (1..12).include?(month)

    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    m = month.to_i
    d = day.to_i
    "%04d-%02d-%02d" % [@year, m, d]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    (Date.new(@year, month, day) - Date.new(@year, 1, 1)).to_i
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless (1..12).include?(month)

    dim = days_in_month(month)
    return false unless dim

    (1..dim).include?(day)
  end

  def get_weekdays_in_month(month)
    dim = days_in_month(month)
    return [] unless dim

    weekday_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..dim).map do |d|
      weekday_names[day_of_week(month, d)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    dim = days_in_month(month)
    return 0 unless dim
    return 0 unless target_day.is_a?(Integer) && (0..6).include?(target_day)

    count = 0
    (1..dim).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end