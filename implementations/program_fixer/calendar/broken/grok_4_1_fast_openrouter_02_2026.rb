require 'date' # No, pure no require.

No, cannot use Date, pure ruby.

class Calendar
  attr_reader :year

  MONTH_NAMES = %w[January February March April May June July August September October November December]
  WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
  DAYS_IN_MONTH = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  def initialize(year_input)
    @year = [(year_input || 0).to_i, 0].max
  end

  def is_leap_year?
    y = @year
    y > 0 && y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)
  end

  def days_in_month(month)
    m = (month || 0).to_i
    return nil unless (1..12).include?(m)
    days = DAYS_IN_MONTH[m]
    days += 1 if m == 2 && is_leap_year?
    days
  end

  def day_of_week(month, day)
    m = (month || 0).to_i
    d = (day || 0).to_i
    return nil unless (1..12).include?(m) && d >= 1
    dim = days_in_month(m)
    return nil unless dim && d <= dim

    mm = m
    yy = @year
    if mm <= 2
      yy -= 1
      mm += 12
    end
    j = yy / 100
    k = yy % 100
    h = (d + (13.0 * (mm + 1) / 5).floor + k + (k / 4).floor + (j / 4).floor - 2 * j) % 7
    h = (h + 7) % 7 # ensure non-neg
    h == 0 ? 6 : h - 1
  end

  def get_month_name(month)
    m = (month || 0).to_i
    MONTH_NAMES[m - 1] if (1..12).include?(m)
  end

  def format_date(month, day)
    m = (month || 0).to_i
    d = (day || 0).to_i
    "%04d-%02d-%02d" % [@year, m, d]
  end

  def get_days_until_date(month, day)
    m = (month || 0).to_i
    d = (day || 0).to_i
    return nil if m < 1 || m > 12 || d < 1
    total = 0
    (1...m).each { |mm| total += (days_in_month(mm) || 0) }
    total + d - 1
  end

  def is_valid_date?(month, day)
    m = (month || 0).to_i
    d = (day || 0).to_i
    return false unless (1..12).include?(m)
    dim = days_in_month(m)
    return false unless dim && (1..dim).include?(d)
    true
  end

  def get_weekdays_in_month(month)
    m = (month || 0).to_i
    return [] unless (1..12).include?(m)
    dim = days_in_month(m)
    return [] unless dim
    weekdays = []
    (1..dim).each do |d|
      dow = day_of_week(m, d)
      weekdays << WEEKDAY_NAMES[dow] if dow
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    target = (target_day || 0).to_i
    return 0 unless (0..6).include?(target)
    m = (month || 0).to_i
    return 0 unless (1..12).include?(m)
    dim = days_in_month(m)
    return 0 unless dim
    count = 0
    (1..dim).each do |d|
      count += 1 if day_of_week(m, d) == target
    end
    count
  end
end