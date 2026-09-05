require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = parse_year(year)
  end

  def is_leap_year?
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    feb_days = is_leap_year? ? 29 : 28
    days = [31, feb_days, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    begin
      Date.new(@year, month, day).wday
    rescue ArgumentError
      nil
    end
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    format("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1
    dim = days_in_month(month)
    return false if dim.nil?
    return false if day > dim
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    dim = days_in_month(month)
    return [] if dim.nil?
    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    weekdays = []
    (1..dim).each do |d|
      weekdays << names[day_of_week(month, d)]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6
    dim = days_in_month(month)
    return 0 if dim.nil?
    count = 0
    (1..dim).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end

  private

  def parse_year(y)
    if y.is_a?(Integer) && y > 0
      y
    elsif y.is_a?(Float) && y.to_i > 0
      y.to_i
    elsif y.is_a?(String) && y.strip.match?(/\A-?\d+\z/) && y.to_i > 0
      y.to_i
    else
      begin
        v = Integer(y)
        v > 0 ? v : Time.now.year
      rescue
        Time.now.year
      end
    end
  end
end