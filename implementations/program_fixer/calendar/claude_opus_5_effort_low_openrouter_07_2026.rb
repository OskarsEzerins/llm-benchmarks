require 'date'

class Calendar
  MONTH_NAMES = %w[January February March April May June July August September
                   October November December].freeze
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  attr_reader :year

  def initialize(year)
    @year = if year.is_a?(Integer) && year > 0
              year
            elsif year.is_a?(String) && year.match?(/\A-?\d+\z/) && year.to_i > 0
              year.to_i
            else
              0
            end
  end

  def valid_year?
    @year > 0
  end

  def is_leap_year?
    return false unless valid_year?
    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)
    month = month.to_i
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month.to_i, day.to_i).wday
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
    return false unless valid_year?
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer) || (day.is_a?(String) && day.match?(/\A\d+\z/))
    d = day.to_i
    return false if d < 1 || d > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month) && valid_year?
    (1..days_in_month(month)).map { |d| DAY_NAMES[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month) && valid_year?
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end

  private

  def valid_month?(month)
    return false unless month.is_a?(Integer) || (month.is_a?(String) && month.match?(/\A\d+\z/))
    month.to_i.between?(1, 12)
  end
end