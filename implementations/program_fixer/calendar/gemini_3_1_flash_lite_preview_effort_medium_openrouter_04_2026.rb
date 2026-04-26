require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    raise ArgumentError unless year.is_a?(Integer) && year > 0
    @year = year
  end

  def is_leap_year?
    (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[2] = 29 if month == 2 && is_leap_year?
    days[month]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    names = %w[January February March April May June July August September October November December]
    names[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    (Date.new(year, month, day) - Date.new(year, 1, 1)).to_i
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    day > 0 && day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).map { |d| names[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end