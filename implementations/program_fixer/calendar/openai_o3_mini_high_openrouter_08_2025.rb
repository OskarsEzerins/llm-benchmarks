require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = 1970
    end
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100 != 0) || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && (1..12).include?(month)
    month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      29
    else
      month_days[month - 1]
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  rescue ArgumentError
    nil
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && (1..12).include?(month)
    month_names = %w[January February March April May June July August September October November December]
    month_names[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total + (day - 1)
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless (1..12).include?(month)
    max_day = days_in_month(month)
    return false if max_day.nil?
    (1..max_day).include?(day)
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && (1..12).include?(month)
    weekdays = []
    total_days = days_in_month(month)
    (1..total_days).each do |d|
      current_wday = day_of_week(month, d)
      weekdays << %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][current_wday]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && (1..12).include?(month)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    count = 0
    total_days = days_in_month(month)
    (1..total_days).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end