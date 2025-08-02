require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : nil
  end

  def is_leap_year?
    return false unless year
    (year % 400).zero? || ((year % 4).zero? && !(year % 100).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month) && year
    return 29 if month == 2 && is_leap_year?
    [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(year, month, day).wday
  end

  def get_month_name(month)
    return nil unless valid_month?(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    (1...month).inject(0) { |sum, m| sum + days_in_month(m) } + day
  end

  def is_valid_date?(month, day)
    return false unless year
    return false unless month.is_a?(Integer) && month.between?(1, 12)
    return false unless day.is_a?(Integer) && day.between?(1, days_in_month(month))
    true
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month) && year
    (1..days_in_month(month)).map do |d|
      %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month) && target_day.is_a?(Integer) && target_day.between?(0, 6)
    (1..days_in_month(month)).count { |d| day_of_week(month, d) == target_day }
  end

  private

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end
end