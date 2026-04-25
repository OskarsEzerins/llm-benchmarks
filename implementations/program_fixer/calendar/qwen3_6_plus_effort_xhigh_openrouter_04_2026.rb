require 'date'

class Calendar
  def initialize(year)
    @year = year.is_a?(Integer) ? year : nil
  end

  def year
    @year
  end

  def is_leap_year?
    return false unless @year.is_a?(Integer)
    (@year % 400 == 0) || ((@year % 4 == 0) && (@year % 100 != 0))
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer)
    return 0 unless (1..12).include?(month)
    
    # Days in each month (1-based index, index 0 is placeholder)
    # Jan=31, Feb=28, Mar=31, Apr=30, May=31, Jun=30, Jul=31, Aug=31, Sep=30, Oct=31, Nov=30, Dec=31
    days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    
    return 29 if month == 2 && is_leap_year?
    days[month]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    begin
      Date.new(@year, month, day).wday
    rescue
      nil
    end
  end

  def get_month_name(month)
    return "Unknown" unless month.is_a?(Integer) && (1..12).include?(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return "Invalid Date" unless is_valid_date?(month, day)
    "#{@year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total += day
    total - 1
  end

  def is_valid_date?(month, day)
    return false unless @year.is_a?(Integer)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    max_day = days_in_month(month)
    return false unless day.between?(1, max_day)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && (1..12).include?(month)
    return [] unless @year.is_a?(Integer)
    
    weekdays = []
    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    d_count = days_in_month(month)
    
    (1..d_count).each do |d|
      dow = day_of_week(month, d)
      weekdays << names[dow] if dow
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && (1..12).include?(month)
    return 0 unless @year.is_a?(Integer)
    
    count = 0
    d_count = days_in_month(month)
    (1..d_count).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end