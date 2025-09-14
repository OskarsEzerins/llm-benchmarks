class Calendar
  attr_reader :year

  def initialize(year)
    @year = if year.is_a?(Integer)
      year
    elsif year.respond_to?(:to_i)
      year.to_i
    else
      0
    end
  end

  def is_leap_year?
    ((@year % 4).zero? && !(@year % 100).zero?) || (@year % 400).zero?
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    require 'date'
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + (day - 1)
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    dim = days_in_month(month)
    return false if dim <= 0
    day.between?(1, dim)
  end

  def get_weekdays_in_month(month)
    dim = days_in_month(month)
    return [] if dim <= 0
    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..dim).map { |d| names[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    dim = days_in_month(month)
    return 0 if dim <= 0
    count = 0
    (1..dim).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end