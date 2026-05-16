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
    return 0 if month.nil? || !month.is_a?(Integer)
    return 0 if month < 1 || month > 12
    
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil if @year.nil?
    return nil if !is_valid_date?(month, day)
    
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    y = @year
    y -= 1 if month < 3
    (y + y / 4 - y / 100 + y / 400 + t[month - 1] + day) % 7
  end

  def get_month_name(month)
    return nil if month.nil? || !month.is_a?(Integer)
    return nil if month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil if @year.nil?
    return nil if !is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return 0 if !is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if @year.nil?
    return false if month.nil? || day.nil?
    return false if !month.is_a?(Integer) || !day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] if !is_valid_date?(month, 1)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      wday = day_of_week(month, d)
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][wday]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if !is_valid_date?(month, 1)
    return 0 if target_day.nil? || !target_day.is_a?(Integer)
    return 0 if target_day < 0 || target_day > 6
    
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end