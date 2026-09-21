require 'date'

class Calendar
  attr_reader :year

  MONTH_NAMES = %w[January February March April May June July August September October November December].freeze
  WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  def initialize(year)
    @year = normalize_year(year)
  end

  def is_leap_year?
    return false unless @year.is_a?(Integer)

    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)

    return 29 if month == 2 && is_leap_year?

    [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless valid_month?(month)

    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format('%04d-%02d-%02d', @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    (Date.new(@year, month, day) - Date.new(@year, 1, 1)).to_i
  end

  def is_valid_date?(month, day)
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer)

    day >= 1 && day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return nil unless valid_month?(month)

    names = []
    (1..days_in_month(month)).each do |d|
      name = WEEKDAY_NAMES[day_of_week(month, d)]
      names << name unless names.include?(name)
    end
    names
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless valid_month?(month)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    (1..days_in_month(month)).count { |d| day_of_week(month, d) == target_day }
  end

  private

  def normalize_year(year)
    year = year.to_i if year.is_a?(String) && year.match?(/\A\d+\z/)
    return nil unless year.is_a?(Integer)
    return nil unless year.positive?

    year
  end

  def valid_month?(month)
    month.is_a?(Integer) && month >= 1 && month <= 12
  end
end