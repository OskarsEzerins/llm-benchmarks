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
    return false if @year.nil?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil if month.nil? || !month.is_a?(Integer)
    return nil if month < 1 || month > 12

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil if month.nil? || day.nil?
    return nil if !month.is_a?(Integer) || !day.is_a?(Integer)
    return nil unless is_valid_date?(month, day)

    date = Date.new(@year, month, day)
    date.wday
  end

  def get_month_name(month)
    return nil if month.nil? || !month.is_a?(Integer)
    return nil if month < 1 || month > 12

    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil if month.nil? || day.nil?
    return nil if !month.is_a?(Integer) || !day.is_a?(Integer)
    return nil unless is_valid_date?(month, day)

    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil if month.nil? || day.nil?
    return nil if !month.is_a?(Integer) || !day.is_a?(Integer)
    return nil unless is_valid_date?(month, day)

    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if month.nil? || day.nil?
    return false if !month.is_a?(Integer) || !day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] if month.nil? || !month.is_a?(Integer)
    return [] if month < 1 || month > 12

    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if month.nil? || target_day.nil?
    return 0 if !month.is_a?(Integer) || !target_day.is_a?(Integer)
    return 0 if month < 1 || month > 12

    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end

require 'date'