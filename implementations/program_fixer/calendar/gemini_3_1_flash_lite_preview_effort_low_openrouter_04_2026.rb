require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    unless year.is_a?(Integer) && year > 0
      raise ArgumentError, "Invalid year: must be a positive integer"
    end
    @year = year
  end

  def is_leap_year?
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[2] = 29 if month == 2 && is_leap_year?
    days[month]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    months = %w[January February March April May June July August September October November December]
    months[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    start_date = Date.new(@year, 1, 1)
    target_date = Date.new(@year, month, day)
    (target_date - start_date).to_i
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month >= 1 && month <= 12
    return false unless day >= 1 && day <= days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    weekdays = []
    days = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).each do |d|
      weekdays << days[day_of_week(month, d)]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end