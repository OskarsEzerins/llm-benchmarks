require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = nil
    end
  end

  def is_leap_year?
    return false if year.nil?
    (year % 4).zero? && (!(year % 100).zero? || (year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless year && month.is_a?(Integer) && (1..12).include?(month)
    days = [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && (1..12).include?(month)
    Date::MONTHNAMES[month]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    format('%d-%02d-%02d', year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(year, month, day).yday - 1
  end

  def is_valid_date?(month, day)
    return false if year.nil?
    Date.valid_date?(year, month, day)
  end

  def get_weekdays_in_month(month)
    num_days = days_in_month(month)
    return [] if num_days.nil?

    (1..num_days).map do |d|
      Date::DAYNAMES[day_of_week(month, d)]
    end
  end

  def count_occurrences_of_day(month, day_of_week)
    num_days = days_in_month(month)
    return 0 unless num_days && day_of_week.is_a?(Integer) && (0..6).include?(day_of_week)

    (1..num_days).count { |d| self.day_of_week(month, d) == day_of_week }
  end
end