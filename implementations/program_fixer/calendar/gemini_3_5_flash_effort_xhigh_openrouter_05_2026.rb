require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : nil
  end

  def is_leap_year?
    return false if @year.nil?
    Date.leap?(@year)
  end

  def days_in_month(month)
    return nil unless @year && month.is_a?(Integer) && month.between?(1, 12)
    Date.new(@year, month, -1).day
  rescue ArgumentError
    nil
  end

  def day_of_week(month, day)
    return nil unless @year && is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  rescue ArgumentError
    nil
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    Date::MONTHNAMES[month]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).yday - 1
  rescue ArgumentError
    nil
  end

  def is_valid_date?(month, day)
    return false unless @year
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    max_days = days_in_month(month)
    return false if max_days.nil?
    day.between?(1, max_days)
  end

  def get_weekdays_in_month(month)
    days = days_in_month(month)
    return [] if days.nil?

    (1..days).map do |d|
      Date::DAYNAMES[day_of_week(month, d)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    days = days_in_month(month)
    return 0 if days.nil? || !target_day.is_a?(Integer) || !target_day.between?(0, 6)

    count = 0
    (1..days).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end