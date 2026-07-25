require 'date'

class Calendar
  MONTH_NAMES = %w[January February March April May June July August
                   September October November December].freeze

  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze

  attr_reader :year

  def initialize(year)
    @year = valid_year?(year) ? year.to_i : 0
  end

  def is_leap_year?
    return false if @year <= 0

    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)

    m = month.to_i
    return 29 if m == 2 && is_leap_year?

    DAYS[m - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    Date.new(@year, month.to_i, day.to_i).wday
  rescue StandardError
    nil
  end

  def get_month_name(month)
    return nil unless valid_month?(month)

    MONTH_NAMES[month.to_i - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format('%04d-%02d-%02d', @year, month.to_i, day.to_i)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    total = 0
    (1...month.to_i).each { |m| total += days_in_month(m) }
    total + day.to_i - 1
  end

  def is_valid_date?(month, day)
    return false unless valid_month?(month)
    return false unless day.is_a?(Numeric) || (day.is_a?(String) && day.match?(/\A-?\d+\z/))

    d = day.to_i
    return false if d < 1
    return false if d > days_in_month(month)

    true
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month)

    (1..days_in_month(month)).map do |d|
      DAY_NAMES[day_of_week(month, d)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end

  private

  def valid_year?(year)
    return false if year.nil?
    return year > 0 if year.is_a?(Integer)
    return year.to_i > 0 if year.is_a?(Float)
    return year.to_i > 0 if year.is_a?(String) && year.match?(/\A-?\d+\z/)

    false
  end

  def valid_month?(month)
    return false if @year <= 0
    return false unless month.is_a?(Numeric) || (month.is_a?(String) && month.match?(/\A-?\d+\z/))

    m = month.to_i
    m >= 1 && m <= 12
  end
end