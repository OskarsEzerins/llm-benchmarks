require 'date'

class Calendar
  attr_reader :year

  MONTH_NAMES = %w[
    January February March April May June
    July August September October November December
  ].freeze

  WEEKDAY_NAMES = %w[
    Sunday Monday Tuesday Wednesday Thursday Friday Saturday
  ].freeze

  def initialize(year)
    @year = normalize_year(year)
  end

  def is_leap_year?
    return false unless valid_year?

    (@year % 4).zero? && ((@year % 100) != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    month = normalize_month(month)
    return nil unless month

    case month
    when 1, 3, 5, 7, 8, 10, 12
      31
    when 4, 6, 9, 11
      30
    when 2
      is_leap_year? ? 29 : 28
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    Date.new(@year, normalize_month(month), normalize_day(day)).wday
  end

  def get_month_name(month)
    month = normalize_month(month)
    return nil unless month

    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format("%04d-%02d-%02d", @year, normalize_month(month), normalize_day(day))
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    month = normalize_month(month)
    day = normalize_day(day)

    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end

    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless valid_year?

    month = normalize_month(month)
    day = normalize_day(day)
    return false unless month && day

    Date.valid_date?(@year, month, day)
  end

  def get_weekdays_in_month(month)
    month = normalize_month(month)
    return [] unless month && valid_year?

    num_days = days_in_month(month)
    return [] unless num_days

    (1..num_days).map do |day|
      WEEKDAY_NAMES[day_of_week(month, day)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    month = normalize_month(month)
    target_day = normalize_weekday(target_day)
    return 0 unless month && target_day && valid_year?

    count = 0
    (1..days_in_month(month)).each do |day|
      count += 1 if day_of_week(month, day) == target_day
    end
    count
  end

  private

  def valid_year?
    @year.is_a?(Integer) && @year.positive?
  end

  def normalize_year(year)
    value = Integer(year)
    value.positive? ? value : 0
  rescue ArgumentError, TypeError
    0
  end

  def normalize_month(month)
    value = Integer(month)
    (1..12).cover?(value) ? value : nil
  rescue ArgumentError, TypeError
    nil
  end

  def normalize_day(day)
    value = Integer(day)
    value.positive? ? value : nil
  rescue ArgumentError, TypeError
    nil
  end

  def normalize_weekday(day)
    value = Integer(day)
    (0..6).cover?(value) ? value : nil
  rescue ArgumentError, TypeError
    nil
  end
end