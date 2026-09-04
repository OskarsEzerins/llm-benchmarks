require "date"

class Calendar
  attr_reader :year

  MONTH_NAMES = %w[
    January February March April May June
    July August September October November December
  ].freeze

  WEEKDAY_NAMES = %w[
    Sunday Monday Tuesday Wednesday Thursday Friday Saturday
  ].freeze

  MONTH_LENGTHS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze

  def initialize(year)
    @year = year.is_a?(Integer) && year.positive? ? year : Date.today.year
  end

  def is_leap_year?
    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 0 unless valid_month?(month)
    return 29 if month == 2 && is_leap_year?

    MONTH_LENGTHS[month - 1]
  end

  def day_of_week(month, day)
    return -1 unless is_valid_date?(month, day)

    Date.new(@year, month, day, Date::GREGORIAN).wday
  end

  def get_month_name(month)
    return "" unless valid_month?(month)

    MONTH_NAMES[month - 1].dup
  end

  def format_date(month, day)
    return "" unless is_valid_date?(month, day)

    format("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return 0 unless is_valid_date?(month, day)

    target = Date.new(@year, month, day, Date::GREGORIAN)
    start = Date.new(@year, 1, 1, Date::GREGORIAN)
    (target - start).to_i
  end

  def is_valid_date?(month, day)
    valid_month?(month) &&
      day.is_a?(Integer) &&
      day.between?(1, days_in_month(month))
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month)

    (1..days_in_month(month)).map do |day|
      WEEKDAY_NAMES[day_of_week(month, day)].dup
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    (1..days_in_month(month)).count do |day|
      day_of_week(month, day) == target_day
    end
  end

  private

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end
end