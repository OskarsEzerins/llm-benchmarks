class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : 2024
  end

  def is_leap_year?
    (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0))
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1] + (month == 2 && is_leap_year? ? 1 : 0)
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    
    require 'date'
    Date.new(year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    
    sprintf("%04d-%02d-%02d", year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    return false unless day.between?(1, days_in_month(month))
    true
  end

  def get_weekdays_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    return nil unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end