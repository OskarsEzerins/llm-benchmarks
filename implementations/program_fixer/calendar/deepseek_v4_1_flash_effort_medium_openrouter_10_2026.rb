class Calendar
  MONTH_NAMES = %w[January February March April May June July August September October November December]
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : 0
  end

  attr_reader :year

  def is_leap_year?
    (@year % 4 == 0) && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)

    days = [31, is_leap_year? ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    m = month
    y = @year

    if m < 3
      m += 12
      y -= 1
    end

    k = y % 100
    j = y / 100
    h = (day + (13 * (m + 1) / 5) + k + (k / 4) + (j / 4) + (5 * j)) % 7

    (h + 6) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)

    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format("%04d-%02d-%02d", @year, month, day)
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
    return false unless dim

    day.between?(1, dim)
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)

    result = []
    (1..days_in_month(month)).each do |d|
      dow = day_of_week(month, d)
      result << DAY_NAMES[dow] if dow
    end
    result
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