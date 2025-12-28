require 'date'

class Calendar
  MONTHS = %w[January February March April May June July August September October November December]
  WEEKDAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
  DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  def initialize(year)
    @year = year.to_i rescue 0
    @year = nil if @year <= 0
  end

  def year
    @year
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil if !month.is_a?(Integer) || month < 1 || month > 12
    return 29 if month == 2 && is_leap_year?
    DAYS_IN_MONTH[month - 1]
  end

  def day_of_week(month, day)
    return nil if !month.is_a?(Integer) || !day.is_a?(Integer)
    return nil if month < 1 || month > 12 || day < 1
    max_days = days_in_month(month)
    return nil if max_days.nil? || day > max_days
    
    Date.new(@year, month, day).wday
  rescue
    nil
  end

  def get_month_name(month)
    return nil if !month.is_a?(Integer) || month < 1 || month > 12
    MONTHS[month - 1]
  end

  def format_date(month, day)
    return nil if !is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil if !is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if !month.is_a?(Integer) || !day.is_a?(Integer)
    return false if @year.nil?
    return false if month < 1 || month > 12
    max_days = days_in_month(month)
    return false if max_days.nil? || day < 1 || day > max_days
    true
  end

  def get_weekdays_in_month(month)
    return [] if !month.is_a?(Integer) || month < 1 || month > 12
    days = days_in_month(month)
    return [] if days.nil?
    
    weekdays = []
    (1..days).each do |d|
      wday = day_of_week(month, d)
      weekdays << WEEKDAYS[wday] unless wday.nil?
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if !month.is_a?(Integer) || !target_day.is_a?(Integer)
    return 0 if month < 1 || month > 12 || target_day < 0 || target_day > 6
    days = days_in_month(month)
    return 0 if days.nil?
    
    count = 0
    (1..days).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end