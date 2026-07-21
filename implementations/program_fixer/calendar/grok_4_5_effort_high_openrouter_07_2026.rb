require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = Integer(year) rescue 0
    @year = 0 if @year < 1
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    month = begin
      Integer(month)
    rescue
      return 0
    end
    return 0 if month < 1 || month > 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    names = %w[January February March April May June July August September October November December]
    month = begin
      Integer(month)
    rescue
      return nil
    end
    return nil if month < 1 || month > 12
    names[month - 1]
  end

  def format_date(month, day)
    month = begin
      Integer(month)
    rescue
      0
    end
    day = begin
      Integer(day)
    rescue
      0
    end
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    month = begin
      Integer(month)
    rescue
      return 0
    end
    day = begin
      Integer(day)
    rescue
      return 0
    end
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if month.nil? || day.nil?
    month = begin
      Integer(month)
    rescue
      return false
    end
    day = begin
      Integer(day)
    rescue
      return false
    end
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    weekdays = []
    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).each do |d|
      name = names[day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end