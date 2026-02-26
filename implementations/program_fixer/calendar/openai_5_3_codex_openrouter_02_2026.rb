require "date"

class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year.positive? ? year : 0
  end

  def is_leap_year?
    return false unless @year.positive?

    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?

    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    Date.new(@year, month, day).wday
  rescue ArgumentError
    nil
  end

  def get_month_name(month)
    return nil unless valid_month?(month)

    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless @year.positive?
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer) && day >= 1

    dim = days_in_month(month)
    !dim.nil? && day <= dim
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month)
    return [] unless @year.positive?

    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).map { |d| names[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    return 0 unless @year.positive?

    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end

  private

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end
end