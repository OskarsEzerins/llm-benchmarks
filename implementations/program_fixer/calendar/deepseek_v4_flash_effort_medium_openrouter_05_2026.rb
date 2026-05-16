class Calendar
  MONTH_NAMES = %w[January February March April May June July August September October November December].freeze
  DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze
  WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  attr_reader :year

  def initialize(year)
    @year = year.to_i
  end

  def is_leap_year?
    (@year % 4 == 0) && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 29 if month == 2 && is_leap_year?
    DAYS_IN_MONTH[month - 1]
  end

  def day_of_week(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    return nil if month < 1 || month > 12 || day < 1 || day > days_in_month(month)

    # Zeller's congruence
    m = month
    y = @year
    if m < 3
      m += 12
      y -= 1
    end
    q = day
    k = y % 100
    j = y / 100
    h = (q + (13 * (m + 1) / 5) + k + (k / 4) + (j / 4) - (2 * j)) % 7
    (h + 6) % 7  # convert to 0=Sunday, 6=Saturday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    return nil if month < 1 || month > 12 || day < 1 || day > days_in_month(month)
    format("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    return nil if month < 1 || month > 12 || day < 1 || day > days_in_month(month)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + (day - 1)
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    weekdays = []
    (1..days_in_month(month)).each do |d|
      wd = day_of_week(month, d)
      weekdays << WEEKDAY_NAMES[wd]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && target_day.is_a?(Integer)
    return 0 if month < 1 || month > 12 || target_day < 0 || target_day > 6
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end