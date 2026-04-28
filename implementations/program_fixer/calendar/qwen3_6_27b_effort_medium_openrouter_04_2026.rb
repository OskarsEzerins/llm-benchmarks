require 'date'

class Calendar
  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : nil
  end

  attr_reader :year

  def is_leap_year?
    return false unless @year
    @year % 4 == 0 && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return false unless month.is_a?(Integer) && month >= 1 && month <= 12 && @year
    if month == 2 && is_leap_year?
      29
    else
      [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
    end
  end

  def day_of_week(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer) && @year && is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return false unless month.is_a?(Integer) && month >= 1 && month <= 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return false unless is_valid_date?(month, day) && @year
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return false unless is_valid_date?(month, day) && @year
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer) && @year
    return false if month < 1 || month > 12
    return false if day < 1
    max_days = days_in_month(month)
    return false unless max_days && day <= max_days
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12 && @year
    weekdays = []
    days = days_in_month(month)
    return [] unless days && days > 0
    (1..days).each do |d|
      wday = day_of_week(month, d)
      weekdays << %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][wday]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && target_day.is_a?(Integer) && @year
    count = 0
    days = days_in_month(month)
    return 0 unless days && days > 0
    (1..days).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end