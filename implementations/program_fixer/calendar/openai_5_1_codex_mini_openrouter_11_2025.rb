require 'date'

class Calendar
  attr_reader :year

  MONTH_NAMES = %w[
    January February March April May June
    July August September October November December
  ].freeze

  MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze
  WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  def initialize(year)
    @year = parse_year(year)
  end

  def is_leap_year?
    return false unless year

    (year % 4).zero? && ((year % 100).nonzero? || (year % 400).zero?)
  end

  def days_in_month(month)
    normalized_month = parse_month(month)
    return nil unless normalized_month

    return 29 if normalized_month == 2 && is_leap_year?

    MONTH_DAYS[normalized_month - 1]
  end

  def day_of_week(month, day)
    date = build_date(month, day)
    date&.wday
  end

  def get_month_name(month)
    normalized_month = parse_month(month)
    return nil unless normalized_month

    MONTH_NAMES[normalized_month - 1]
  end

  def format_date(month, day)
    date = build_date(month, day)
    return nil unless date

    format('%04d-%02d-%02d', date.year, date.month, date.day)
  end

  def get_days_until_date(month, day)
    target_date = build_date(month, day)
    return nil unless target_date

    start_of_year = Date.new(year, 1, 1)
    (target_date - start_of_year).to_i
  end

  def is_valid_date?(month, day)
    !build_date(month, day).nil?
  end

  def get_weekdays_in_month(month)
    normalized_month = parse_month(month)
    return [] unless normalized_month

    total_days = days_in_month(normalized_month)
    return [] unless total_days

    (1..total_days).map do |day_index|
      weekday_index = day_of_week(normalized_month, day_index)
      WEEKDAY_NAMES[weekday_index] if weekday_index
    end.compact
  end

  def count_occurrences_of_day(month, target_day)
    normalized_month = parse_month(month)
    desired_day = parse_day_of_week(target_day)
    return 0 unless normalized_month && desired_day

    total_days = days_in_month(normalized_month)
    return 0 unless total_days

    (1..total_days).count do |day_index|
      day_of_week(normalized_month, day_index) == desired_day
    end
  end

  private

  def build_date(month, day)
    return nil unless year

    normalized_month = parse_month(month)
    normalized_day = parse_day(day)
    return nil unless normalized_month && normalized_day

    Date.new(year, normalized_month, normalized_day)
  rescue Date::Error
    nil
  end

  def parse_year(value)
    normalized = Integer(value)
    return nil if normalized <= 0

    normalized
  rescue ArgumentError, TypeError
    nil
  end

  def parse_month(value)
    normalized = Integer(value)
    (1..12).include?(normalized) ? normalized : nil
  rescue ArgumentError, TypeError
    nil
  end

  def parse_day(value)
    normalized = Integer(value)
    normalized.positive? ? normalized : nil
  rescue ArgumentError, TypeError
    nil
  end

  def parse_day_of_week(value)
    normalized = Integer(value)
    normalized.between?(0, 6) ? normalized : nil
  rescue ArgumentError, TypeError
    nil
  end
end