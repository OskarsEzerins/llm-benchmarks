require 'date'

class Calendar
  def initialize(year)
    unless year.is_a?(Integer) && year.positive?
      raise ArgumentError, "Year must be a positive integer"
    end
    @year = year
  end

  def year
    @year
  end

  def is_leap_year?
    (@year % 4 == 0) && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    
    Date.civil(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    
    month_names = %w[January February March April May June July August September October November December]
    month_names[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    
    total_days = 0
    (1...month).each do |m|
      total_days += days_in_month(m)
    end
    total_days + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    return false unless day.between?(1, 31)

    dim = days_in_month(month)
    return false unless dim
    day <= dim
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)
    
    dim = days_in_month(month)
    return [] unless dim

    weekdays = []
    weekday_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..dim).each do |d|
      dow = day_of_week(month, d)
      weekdays << weekday_names[dow] if dow
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    dim = days_in_month(month)
    return 0 unless dim

    count = 0
    (1..dim).each do |d|
      dow = day_of_week(month, d)
      count += 1 if dow == target_day
    end
    count
  end
end