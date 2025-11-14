require 'date'

class Calendar
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze
  MONTH_NAMES = %w[January February March April May June July August September October November December].freeze

  attr_reader :year

  def initialize(year)
    @year = sanitize_year(year)
  end

  def is_leap_year?
    ((year % 4).zero? && !(year % 100).zero?) || (year % 400).zero?
  end

  def days_in_month(month)
    month = sanitize_month(month)
    return nil unless month

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    Date.new(year, month, day).wday
  end

  def get_month_name(month)
    month = sanitize_month(month)
    month ? MONTH_NAMES[month - 1] : nil
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format('%<year>04d-%<month>02d-%<day>02d', year: year, month: month, day: day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    (Date.new(year, month, day) - Date.new(year, 1, 1)).to_i
  end

  def is_valid_date?(month, day)
    month = sanitize_month(month)
    day = sanitize_day(day)
    return false unless month && day && day >= 1

    max_days = days_in_month(month)
    return false unless max_days

    day <= max_days
  end

  def get_weekdays_in_month(month)
    month = sanitize_month(month)
    return [] unless month

    (1..days_in_month(month)).map { |d| DAY_NAMES[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    month = sanitize_month(month)
    day_index = Integer(target_day) rescue nil
    return 0 unless month && day_index && day_index.between?(0, 6)

    (1..days_in_month(month)).count { |d| day_of_week(month, d) == day_index }
  end

  private

  def sanitize_year(value)
    year = Integer(value) rescue nil
    year = nil if year && year <= 0
    year || Date.today.year
  end

  def sanitize_month(value)
    month = Integer(value) rescue nil
    return nil unless month&.between?(1, 12)

    month
  end

  def sanitize_day(value)
    Integer(value) rescue nil
  end
end