require 'date'

class Calendar
  def initialize(year)
    @year = begin
      y = year.to_i
      y.positive? ? y : 2023
    rescue
      2023
    end
  end

  attr_reader :year

  def is_leap_year?
    @year % 4 == 0 && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless (1..12).cover?(month)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    month == 2 && is_leap_year? ? 29 : days[month - 1]
  end

  def day_of_week(month, day)
    Date.new(@year, month, day).wday
  rescue ArgumentError
    nil
  end

  def get_month_name(month)
    %w[January February March April May June July August September October November December][month - 1] rescue nil
  end

  def format_date(month, day)
    m = month.to_i rescue 0
    d = day.to_i rescue 0
    "%04d-%02d-%02d" % [@year, m, d]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless (1..12).cover?(month)
    day.between?(1, days_in_month(month))
  end

  def get_weekdays_in_month(month)
    days = days_in_month(month)
    return [] unless days
    weekdays = []
    (1..days).each do |d|
      dow = day_of_week(month, d)
      weekdays << %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][dow] if dow
    end
    weekdays
  rescue
    []
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless (0..6).cover?(target_day)
    days = days_in_month(month)
    return 0 unless days
    count = 0
    (1..days).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  rescue
    0
  end
end