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
    return false unless @year
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless (1..12).include?(month) && @year
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1] += 1 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    require 'date'
    Date.new(@year, month, day).cwday % 7
  end

  def get_month_name(month)
    return nil unless (1..12).include?(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    require 'date'
    target_date = Date.new(@year, month, day)
    start_date = Date.new(@year, 1, 1)
    (target_date - start_date).to_i
  end

  def is_valid_date?(month, day)
    return false unless (1..12).include?(month) && (1..31).include?(day) && @year
    days = days_in_month(month)
    day >= 1 && day <= days
  end

  def get_weekdays_in_month(month)
    return [] unless (1..12).include?(month)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless (1..12).include?(month) && (0..6).include?(target_day)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end