class Calendar
  MONTH_NAMES = %w[January February March April May June July August September October November December].freeze
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze
  DAYS_IN_COMMON_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze

  attr_reader :year

  def initialize(year)
    @year = normalize_year(year)
  end

  def is_leap_year?
    return false unless @year.is_a?(Integer) && @year > 0
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return is_leap_year? ? 29 : 28 if month == 2
    DAYS_IN_COMMON_MONTH[month - 1]
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
    h = (day + (13 * (m + 1)) / 5 + k + k / 4 + j / 4 + 5 * j) % 7
    (h + 6) % 7
  end

  def get_month_name(month)
    return "" unless month.is_a?(Integer) && month.between?(1, 12)
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return "" unless is_valid_date?(month, day)
    format("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return 0 unless is_valid_date?(month, day)

    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless @year.is_a?(Integer) && @year > 0
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    day >= 1 && day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] unless @year.is_a?(Integer) && @year > 0
    return [] unless month.is_a?(Integer) && month.between?(1, 12)

    days = days_in_month(month)
    (1..days).map { |d| DAY_NAMES[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless @year.is_a?(Integer) && @year > 0
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    days = days_in_month(month)
    (1..days).count { |d| day_of_week(month, d) == target_day }
  end

  private

  def normalize_year(year)
    if year.is_a?(Integer)
      year > 0 ? year : 0
    elsif year.is_a?(String) && year.match?(/\A\d+\z/)
      value = year.to_i
      value > 0 ? value : 0
    else
      0
    end
  end
end