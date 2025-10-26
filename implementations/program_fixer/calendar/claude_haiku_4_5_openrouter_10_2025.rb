class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : nil
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil if month.nil? || !month.is_a?(Integer) || month < 1 || month > 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil if month.nil? || day.nil? || !is_valid_date?(month, day)
    # Zeller's congruence algorithm
    m = month < 3 ? month + 12 : month
    y = month < 3 ? @year - 1 : @year
    k = y % 100
    j = y / 100
    h = (day + (13 * (m + 1)) / 5 + k + k / 4 + j / 4 - 2 * j) % 7
    (h + 6) % 7
  end

  def get_month_name(month)
    return nil if month.nil? || !month.is_a?(Integer) || month < 1 || month > 12
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
    return false if month.nil? || day.nil?
    return false if !month.is_a?(Integer) || !day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1
    return false if day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return nil if month.nil? || !month.is_a?(Integer) || month < 1 || month > 12
    weekdays = []
    day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).each do |d|
      dow = day_of_week(month, d)
      weekdays << day_names[dow]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil if month.nil? || target_day.nil?
    return nil if !month.is_a?(Integer) || !target_day.is_a?(Integer)
    return nil if month < 1 || month > 12
    return nil if target_day < 0 || target_day > 6
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end