require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = 0
    end
  end

  def is_leap_year?
    return false unless @year > 0
    (@year % 4).zero? && ((@year % 100 != 0) || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
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
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    Date::MONTHNAMES[month]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    target_date = Date.new(@year, month, day)
    start_date = Date.new(@year, 1, 1)
    (target_date - start_date).to_i
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month >= 1 && month <= 12
    return false unless day >= 1 && day <= days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    (1..days_in_month(month)).map do |d|
      Date::DAYNAMES[day_of_week(month, d)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    (1..days_in_month(month)).count { |d| day_of_week(month, d) == target_day }
  end
end