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
    return false if @year.nil?
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    return 29 if month == 2 && is_leap_year?
    
    days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    format("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    start_date = Date.new(@year, 1, 1)
    target_date = Date.new(@year, month, day)
    (target_date - start_date).to_i
  end

  def is_valid_date?(month, day)
    return false if @year.nil?
    return false unless month.is_a?(Integer) && month.between?(1, 12)
    return false unless day.is_a?(Integer)
    
    max_days = days_in_month(month)
    return false if max_days.nil?
    day.between?(1, max_days)
  end

  def get_weekdays_in_month(month)
    return nil unless is_valid_date?(month, 1)
    weekdays = []
    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).each do |d|
      weekdays << names[day_of_week(month, d)]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless is_valid_date?(month, 1)
    return nil unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end