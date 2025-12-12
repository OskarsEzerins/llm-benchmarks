require "date"

class Calendar
  MONTH_NAMES = %w[
    January February March April May June July August September October November December
  ].freeze

  WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  attr_reader :year

  def initialize(year)
    @year = begin
      y = Integer(year)
      y > 0 ? y : 1
    rescue ArgumentError, TypeError
      1
    end
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100) != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    m = coerce_int(month)
    return nil unless m && (1..12).cover?(m)

    case m
    when 2
      is_leap_year? ? 29 : 28
    when 4, 6, 9, 11
      30
    else
      31
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    Date.new(@year, month.to_i, day.to_i).wday
  rescue ArgumentError
    nil
  end

  def get_month_name(month)
    m = coerce_int(month)
    return nil unless m && (1..12).cover?(m)

    MONTH_NAMES[m - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format("%04d-%02d-%02d", @year, month.to_i, day.to_i)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    Date.new(@year, month.to_i, day.to_i).yday - 1
  rescue ArgumentError
    nil
  end

  def is_valid_date?(month, day)
    m = coerce_int(month)
    d = coerce_int(day)
    return false unless m && d
    return false unless (1..12).cover?(m)

    dim = days_in_month(m)
    return false unless dim

    (1..dim).cover?(d)
  end

  def get_weekdays_in_month(month)
    dim = days_in_month(month)
    return [] unless dim

    m = month.to_i
    (1..dim).map do |d|
      w = day_of_week(m, d)
      w.nil? ? nil : WEEKDAY_NAMES[w]
    end.compact
  end

  def count_occurrences_of_day(month, target_day)
    dim = days_in_month(month)
    t = coerce_int(target_day)
    return 0 unless dim && t && (0..6).cover?(t)

    m = month.to_i
    count = 0
    (1..dim).each do |d|
      count += 1 if day_of_week(m, d) == t
    end
    count
  end

  private

  def coerce_int(value)
    return nil if value.nil?
    return value if value.is_a?(Integer)

    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end
end