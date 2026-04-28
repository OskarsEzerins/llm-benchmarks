require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = year
  end

  def is_leap_year?
    return false unless @year.is_a?(Integer) && @year > 0
    @year % 4 == 0 && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && (1..12).cover?(month)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer) && is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && (1..12).cover?(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer) && is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer) && is_valid_date?(month, day)
    total = day - 1
    (1...month).each { |m| total += days_in_month(m) }
    total
  end

  def is_valid_date?(month, day)
    return false unless @year.is_a?(Integer) && @year > 0
    return false unless month.is_a?(Integer) && (1..12).cover?(month)
    return false unless day.is_a?(Integer) && day >= 1
    day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && (1..12).cover?(month)
    days_in = days_in_month(month)
    return [] if days_in.nil?
    day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in).map { |d| day_names[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && (1..12).cover?(month) && target_day.is_a?(Integer) && (0..6).cover?(target_day)
    count = 0
    days_in = days_in_month(month)
    return 0 if days_in.nil?
    (1..days_in).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end