require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Numeric) ? year.to_i : (year.to_s.to_i rescue 0)
    @year = 0 if @year < 0
  end

  def is_leap_year?
    return false if @year <= 0
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    m = month.to_i rescue 0
    return 0 if m < 1 || m > 12
    case m
    when 1, 3, 5, 7, 8, 10, 12 then 31
    when 4, 6, 9, 11 then 30
    when 2
      is_leap_year? ? 29 : 28
    else
      0
    end
  end

  def day_of_week(month, day)
    m = month.to_i rescue 0
    d = day.to_i rescue 0
    return nil unless is_valid_date?(m, d)
    begin
      Date.new(@year, m, d).wday
    rescue ArgumentError
      nil
    end
  end

  def get_month_name(month)
    m = month.to_i rescue 0
    return nil if m < 1 || m > 12
    %w[January February March April May June July August September October November December][m - 1]
  end

  def format_date(month, day)
    m = month.to_i rescue 0
    d = day.to_i rescue 0
    sprintf("%04d-%02d-%02d", @year, m, d)
  end

  def get_days_until_date(month, day)
    m = month.to_i rescue 0
    d = day.to_i rescue 0
    return 0 unless is_valid_date?(m, d)
    total = 0
    (1...m).each { |idx| total += days_in_month(idx) }
    total + d - 1
  end

  def is_valid_date?(month, day)
    m = month.to_i rescue 0
    d = day.to_i rescue 0
    return false if m < 1 || m > 12
    return false if d < 1 || d > days_in_month(m)
    true
  end

  def get_weekdays_in_month(month)
    m = month.to_i rescue 0
    return [] unless m.between?(1, 12)
    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(m)).map do |d|
      wday = day_of_week(m, d)
      wday ? names[wday] : nil
    end.compact
  end

  def count_occurrences_of_day(month, target_day)
    m = month.to_i rescue 0
    target = target_day.to_i rescue -1
    return 0 if m < 1 || m > 12 || !target.between?(0, 6)
    count = 0
    (1..days_in_month(m)).each do |d|
      count += 1 if day_of_week(m, d) == target
    end
    count
  end
end