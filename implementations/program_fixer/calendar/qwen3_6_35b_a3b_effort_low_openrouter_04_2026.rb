require 'date'

class Calendar
  def initialize(year)
    @year = year
  end

  def is_leap_year?
    return false if @year.nil? || !@year.is_a?(Integer)
    (@year % 4 == 0) && ((@year % 100 != 0) || (@year % 400 == 0))
  end

  def days_in_month(month)
    return 0 if month.nil? || month < 1 || month > 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1] + (month == 2 && is_leap_year? ? 1 : 0)
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return "" if month.nil? || month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return "" unless is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return 0 unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if month.nil? || day.nil? || month < 1 || month > 12 || day < 1
    day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] if month.nil? || month < 1 || month > 12
    days = days_in_month(month)
    (1..days).map { |d| %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if month.nil? || month < 1 || month > 12
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end