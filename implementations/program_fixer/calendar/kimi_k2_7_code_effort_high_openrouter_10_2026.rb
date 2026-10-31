require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = valid_year?(year) ? year.to_i : Time.now.year
  end

  def is_leap_year?
    (@year % 4).zero? && (@year % 100 != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)

    return 29 if month == 2 && is_leap_year?

    [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
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

    Date.new(@year, month, day).strftime('%Y-%m-%d')
  rescue ArgumentError
    nil
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    Date.new(@year, month, day).yday - 1
  rescue ArgumentError
    nil
  end

  def is_valid_date?(month, day)
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer)

    day >= 1 && day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month)

    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).map { |day| names[day_of_week(month, day)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    (1..days_in_month(month)).count { |day| day_of_week(month, day) == target_day }
  end

  private

  def valid_year?(year)
    year.is_a?(Integer) && year.positive?
  end

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end
end