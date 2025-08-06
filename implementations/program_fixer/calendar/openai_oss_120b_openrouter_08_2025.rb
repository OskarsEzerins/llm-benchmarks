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

  NON_LEAP_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze

  def initialize(year)
    @year = valid_year?(year) ? year.to_i : nil
  end

  # ---- Helpers --------------------------------------------------------------

  def valid_year?(y)
    y.is_a?(Integer) && y.positive?
  end

  def valid_month?(m)
    m.is_a?(Integer) && m.between?(1, 12)
  end

  def valid_day?(m, d)
    return false unless valid_month?(m) && d.is_a?(Integer) && d.positive?
    d <= days_in_month(m)
  end

  # ---- Core Date Operations -------------------------------------------------

  def is_leap_year?
    return false unless year
    (year % 4).zero? && ((year % 100).nonzero? || (year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)
    return 29 if month == 2 && is_leap_year?
    NON_LEAP_DAYS[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(year, month, day).wday
  end

  def get_month_name(month)
    return nil unless valid_month?(month)
    MONTH_NAMES[month - 1]
  end

  # ---- Formatting -----------------------------------------------------------

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    format('%04d-%02d-%02d', year, month, day)
  end

  # ---- Calculations ---------------------------------------------------------

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    days_before = (1...month).sum { |m| days_in_month(m) }
    days_before + (day - 1)
  end

  def is_valid_date?(month, day)
    return false unless year
    valid_day?(month, day)
  end

  # ---- Month Analysis -------------------------------------------------------

  def get_weekdays_in_month(month)
    return nil unless valid_month?(month) && year
    (1..days_in_month(month)).map do |d|
      WEEKDAY_NAMES[day_of_week(month, d)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless valid_month?(month) && target_day.is_a?(Integer) && target_day.between?(0, 6) && year
    (1..days_in_month(month)).count { |d| day_of_week(month, d) == target_day }
  end
end