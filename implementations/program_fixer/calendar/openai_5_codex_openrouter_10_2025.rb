require 'date'

class Calendar
  attr_reader :year

  MONTH_NAMES = %w[January February March April May June July August September October November December].freeze
  WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze
  DEFAULT_YEAR = Date.today.year

  def initialize(year)
    coerced_year = begin
      Integer(year)
    rescue ArgumentError, TypeError
      nil
    end

    if coerced_year.nil? || coerced_year.zero?
      @year = DEFAULT_YEAR
    elsif coerced_year.positive?
      @year = coerced_year
    else
      @year = coerced_year.abs
    end
  end

  def is_leap_year?
    Date.gregorian_leap?(year)
  end

  def days_in_month(month)
    m = normalize_month(month)
    return nil unless m

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

    Date.new(year, Integer(month), Integer(day)).wday
  rescue ArgumentError
    nil
  end

  def get_month_name(month)
    m = normalize_month(month)
    return nil unless m

    MONTH_NAMES[m - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format('%04d-%02d-%02d', year, Integer(month), Integer(day))
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    m = Integer(month)
    d = Integer(day)
    days = 0
    (1...m).each { |current_month| days += days_in_month(current_month) }
    days + (d - 1)
  end

  def is_valid_date?(month, day)
    m = normalize_month(month)
    d = normalize_integer(day)
    return false unless m && d

    month_days = days_in_month(m)
    return false unless month_days

    d.between?(1, month_days)
  end

  def get_weekdays_in_month(month)
    m = normalize_month(month)
    return [] unless m

    total_days = days_in_month(m)
    return [] unless total_days

    (1..total_days).map do |d|
      WEEKDAY_NAMES[day_of_week(m, d)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    m = normalize_month(month)
    day_index = normalize_day_of_week(target_day)
    return 0 unless m && day_index

    total_days = days_in_month(m)
    return 0 unless total_days

    (1..total_days).count { |d| day_of_week(m, d) == day_index }
  end

  private

  def normalize_month(month)
    value = normalize_integer(month)
    return nil unless value&.between?(1, 12)

    value
  end

  def normalize_day_of_week(day)
    value = normalize_integer(day)
    return nil unless value&.between?(0, 6)

    value
  end

  def normalize_integer(value)
    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end
end