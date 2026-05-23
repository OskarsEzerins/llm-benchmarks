require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = (year.is_a?(Numeric) || (year.is_a?(String) && year.match?(/^\d+$/))) && year.to_i > 0 ? year.to_i : 0
  end

  def is_leap_year?
    return false if @year <= 0
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 29 if month == 2 && is_leap_year?
    
    [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    %w[Nil January February March April May June July August September October November December][month]
  end

  def format_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return 0 unless is_valid_date?(month, day)
    
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if @year <= 0
    return false unless month.is_a?(Integer) && month.between?(1, 12)
    return false unless day.is_a?(Integer) && day.between?(1, days_in_month(month))
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)
    
    weekdays_map = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).map do |d|
      weekdays_map[day_of_week(month, d)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end