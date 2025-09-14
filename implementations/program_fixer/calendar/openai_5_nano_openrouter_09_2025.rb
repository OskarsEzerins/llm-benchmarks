class Calendar
  WEEKDAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
  MONTH_NAMES = %w[January February March April May June July August September October November December]

  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) ? year : nil
  end

  def is_leap_year?
    return false unless @year.is_a?(Integer) && @year > 0
    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      29
    else
      days[month - 1]
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    y = @year
    m = month
    d = day
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    y -= 1 if m < 3
    (y + y/4 - y/100 + y/400 + t[m - 1] + d) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [ @year, month, day ]
  end

  def get_days_until_date(month, day)
    doy = day_of_year(month, day)
    return nil unless doy
    doy - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month >= 1 && month <= 12
    max = days_in_month(month)
    max && day >= 1 && day <= max
  end

  def get_weekdays_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    (1..days_in_month(month)).map { |d| WEEKDAYS[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end

  private

  def day_of_year(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day
  end
end