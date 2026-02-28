class Calendar
  attr_reader :year

  def initialize(year)
    begin
      y = Integer(year)
    rescue
      y = 0
    end
    @year = y > 0 ? y : 0
  end

  def is_leap_year?
    (@year % 4).zero? && ( (@year % 100).nonzero? || (@year % 400).zero? )
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1,12)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      29
    else
      days[month-1]
    end
  end

  def day_of_week(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    return nil unless month.between?(1,12)
    dim = days_in_month(month)
    return nil if dim.nil? || day < 1 || day > dim
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    y = @year
    if month < 3
      y -= 1
    end
    (y + y/4 - y/100 + y/400 + t[month-1] + day) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1,12)
    %w[January February March April May June July August September October November December][month-1]
  end

  def format_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    return nil unless month.between?(1,12)
    dim = days_in_month(month)
    return nil if dim.nil? || day < 1 || day > dim
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    dim = days_in_month(month)
    return false if dim.nil? || day < 1 || day > dim
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1,12)
    dim = days_in_month(month)
    return [] if dim.nil?
    weekdays = []
    (1..dim).each do |d|
      dow = day_of_week(month, d)
      weekdays << %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][dow]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && target_day.is_a?(Integer)
    return 0 unless month.between?(1,12) && target_day.between?(0,6)
    dim = days_in_month(month)
    return 0 if dim.nil?
    count = 0
    (1..dim).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end