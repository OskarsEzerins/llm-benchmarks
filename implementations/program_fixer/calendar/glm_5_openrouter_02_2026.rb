require 'date'

class Calendar
  def initialize(year)
    if year.nil? || !year.is_a?(Integer) || year < 0
      @year = nil
    else
      @year = year
    end
  end

  def year
    @year
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil if month.nil? || !month.is_a?(Integer) || month < 1 || month > 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    result = days[month - 1]
    result = 29 if month == 2 && is_leap_year?
    result
  end

  def day_of_week(month, day)
    return nil if @year.nil?
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil if month.nil? || !month.is_a?(Integer) || month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "#{@year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if @year.nil?
    return false if month.nil? || !month.is_a?(Integer) || month < 1 || month > 12
    return false if day.nil? || !day.is_a?(Integer) || day < 1
    day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    return [] if @year.nil?
    weekdays = []
    day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).each do |d|
      name = day_names[day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6
    return 0 if @year.nil?
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end