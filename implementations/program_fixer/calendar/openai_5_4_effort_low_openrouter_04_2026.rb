require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year =
      if year.is_a?(Integer) && year >= 0
        year
      elsif year.respond_to?(:to_i)
        converted = year.to_i
        converted >= 0 ? converted : 0
      else
        0
      end
  end

  def is_leap_year?
    return false if @year <= 0

    (@year % 4).zero? && ((@year % 100) != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?

    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    return nil if @year <= 0

    Date.new(@year, month, day).wday
  rescue ArgumentError
    nil
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)

    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format('%04d-%02d-%02d', @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)

    max_days = days_in_month(month)
    return false if max_days.nil?

    day.between?(1, max_days)
  end

  def get_weekdays_in_month(month)
    max_days = days_in_month(month)
    return [] if max_days.nil?

    weekday_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..max_days).map { |d| weekday_names[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    max_days = days_in_month(month)
    return 0 if max_days.nil?
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    count = 0
    (1..max_days).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end