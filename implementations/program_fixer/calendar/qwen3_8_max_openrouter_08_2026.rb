class Calendar
  MONTH_NAMES = %w[January February March April May June July August September October November December].freeze
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  attr_reader :year

  def initialize(year)
    @year = normalize_year(year)
  end

  def is_leap_year?
    return false unless @year.is_a?(Integer) && @year.positive?

    (@year % 4).zero? && ((@year % 100) != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)

    case month
    when 1, 3, 5, 7, 8, 10, 12 then 31
    when 4, 6, 9, 11 then 30
    when 2 then is_leap_year? ? 29 : 28
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    y = @year
    m = month

    if m < 3
      y -= 1
      m += 12
    end

    q = day
    k = y % 100
    j = y / 100

    h = (q + (13 * (m + 1) / 5) + k + (k / 4) + (j / 4) + (5 * j)) % 7
    (h + 6) % 7
  end

  def get_month_name(month)
    return nil unless valid_month?(month)

    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format('%04d-%02d-%02d', @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer) && day >= 1

    max_days = days_in_month(month)
    return false unless max_days

    day <= max_days
  end

  def get_weekdays_in_month(month)
    days = days_in_month(month)
    return [] unless days

    weekdays = []
    (1..days).each do |d|
      dow = day_of_week(month, d)
      weekdays << DAY_NAMES[dow] if dow
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    days = days_in_month(month)
    return 0 unless days

    (1..days).count { |d| day_of_week(month, d) == target_day }
  end

  private

  def normalize_year(value)
    parsed = begin
      Integer(value)
    rescue TypeError, ArgumentError, RangeError
      nil
    end

    parsed.is_a?(Integer) && parsed.positive? ? parsed : 0
  end

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end
end