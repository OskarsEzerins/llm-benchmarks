class Calendar
  MONTH_NAMES = %w[January February March April May June July August September October November December]
  WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : nil
  end

  def year
    @year
  end

  def is_leap_year?
    return false unless @year
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)
    if month == 2
      is_leap_year? ? 29 : 28
    else
      [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day) && @year
    # Zeller's Congruence algorithm
    m = month
    y = @year
    if m < 3
      m += 12
      y -= 1
    end
    k = y % 100
    j = y / 100
    h = (day + ((13 * (m + 1)) / 5).floor + k + (k / 4).floor + (j / 4).floor + 5 * j) % 7
    # Adjust so that 0 = Sunday, ..., 6 = Saturday
    (h + 6) % 7
  end

  def get_month_name(month)
    return nil unless valid_month?(month)
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day) && @year
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day) && @year
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day
  end

  def is_valid_date?(month, day)
    return false unless valid_month?(month) && day.is_a?(Integer)
    max_day = days_in_month(month)
    return false unless max_day
    day >= 1 && day <= max_day
  end

  def get_weekdays_in_month(month)
    return nil unless valid_month?(month) && @year
    weekdays = []
    (1..days_in_month(month)).each do |d|
      day_index = day_of_week(month, d)
      weekdays << WEEKDAY_NAMES[day_index] if day_index
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month) && target_day.between?(0, 6)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end

  private

  def valid_month?(month)
    month.is_a?(Integer) && month >= 1 && month <= 12
  end
end