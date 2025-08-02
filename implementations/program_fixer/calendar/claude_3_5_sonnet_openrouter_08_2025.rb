class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.to_i if year.to_i > 0
    @year ||= 2000
  end

  def is_leap_year?
    return false unless @year
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.to_i.between?(1, 12)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    month = month.to_i
    return days[month-1] + (month == 2 && is_leap_year? ? 1 : 0)
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    m = month.to_i
    y = @year
    if m < 3
      m += 12
      y -= 1
    end
    h = (day + ((13 * (m + 1)) / 5) + y + (y / 4) - (y / 100) + (y / 400)) % 7
    (h + 6) % 7
  end

  def get_month_name(month)
    return nil unless month.to_i.between?(1, 12)
    %w[January February March April May June July August September October November December][month.to_i - 1]
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
    return false unless month && day
    month = month.to_i
    day = day.to_i
    return false unless month.between?(1, 12)
    return false unless day.between?(1, days_in_month(month))
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.to_i.between?(1, 12)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.to_i.between?(1, 12) && target_day.to_i.between?(0, 6)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end