require "date"

class Calendar
  MONTH_NAMES = [
    "January", "February", "March", "April",
    "May", "June", "July", "August",
    "September", "October", "November", "December"
  ].freeze

  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year.positive? ? year : 0
  end

  def is_leap_year?
    return false unless valid_year?

    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_year? && valid_month?(month)

    case month
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

    Date.new(@year, month, day, Date::GREGORIAN).wday
  end

  def get_month_name(month)
    return nil unless valid_month?(month)

    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    total = 0
    (1...month).each do |current_month|
      total += days_in_month(current_month)
    end

    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless valid_year? && valid_month?(month)
    return false unless day.is_a?(Integer)

    day.between?(1, days_in_month(month))
  end

  def get_weekdays_in_month(month)
    days = days_in_month(month)
    return [] unless days

    (1..days).map do |day|
      %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, day)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    days = days_in_month(month)
    return 0 unless days
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    (1..days).count { |day| day_of_week(month, day) == target_day }
  end

  private

  def valid_year?
    @year.is_a?(Integer) && @year.positive?
  end

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end
end