class Calendar
  attr_reader :year

  def initialize(yr)
    @year = yr.is_a?(Integer) && yr > 0 ? yr : nil
  end

  def is_leap_year?
    return false unless @year.is_a?(Integer) && @year > 0
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless (1..12).include?(month)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless @year.is_a?(Integer) && @year > 0 && month && day && (1..12).include?(month)
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    y = @year
    y -= 1 if month < 3
    (y + y/4 - y/100 + y/400 + t[month-1] + day) % 7
  end

  def get_month_name(month)
    return nil unless (1..12).include?(month)
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
    return false unless month && day && (1..12).include?(month)
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless (1..12).include?(month)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless (1..12).include?(month)
    count = 0
    days = days_in_month(month)
    (1..days).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end