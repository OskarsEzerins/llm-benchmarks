class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.to_i if year.is_a?(Numeric) || year.to_s =~ /^\d+$/
    @year = 0 unless @year.is_a?(Integer) && @year > 0
    @year = @year.to_i
  end

  def is_leap_year?
    return false unless @year > 0
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return -1 unless is_valid_date?(month, day)
    require 'date'
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return "" unless month.is_a?(Integer) && month.between?(1, 12)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return "" unless is_valid_date?(month, day)
    "#{@year.to_s.rjust(4, '0')}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return 0 unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && month.between?(1, 12)
    return false unless day.is_a?(Integer) && day > 0
    day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
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