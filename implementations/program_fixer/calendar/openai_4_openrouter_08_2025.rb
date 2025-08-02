require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : 1
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil if month.nil? || month < 1 || month > 12
    days = [nil, 31, is_leap_year? ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil if month.nil? || month < 1 || month > 12
    Date::MONTHNAMES[month]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "#{@year}-#{'%02d' % month}-#{'%02d' % day}"
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    target_date = Date.new(@year, month, day)
    start_date = Date.new(@year, 1, 1)
    (target_date - start_date).to_i
  end

  def is_valid_date?(month, day)
    return false if month.nil? || day.nil?
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return nil unless month.between?(1, 12)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = Date::DAYNAMES[day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless month.between?(1, 12) && target_day.between?(0, 6)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end