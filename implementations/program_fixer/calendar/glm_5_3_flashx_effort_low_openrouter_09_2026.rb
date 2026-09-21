class Calendar
  MONTH_NAMES = %w[January February March April May June July August September October November December].freeze
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  attr_reader :year

  def initialize(year)
    @year = normalize_year(year)
  end

  def is_leap_year?
    return false unless valid_year?
    (year % 4).zero? && (!(year % 100).zero? || (year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)
    return 29 if month == 2 && is_leap_year?
    return 28 if month == 2
    [31, nil, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1] || [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    days = 0
    (1...month).each { |m| days += days_in_month(m) }
    (days + day - 1) % 7
  end

  def get_month_name(month)
    return nil unless valid_month?(month)
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    format('%04d-%02d-%02d', year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = day
    (1...month).each { |m| total += days_in_month(m) }
    total - 1
  end

  def is_valid_date?(month, day)
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer) && day >= 1
    day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return nil unless valid_month?(month)
    (1..days_in_month(month)).map { |d| DAY_NAMES[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless valid_month?(month)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    (1..days_in_month(month)).count { |d| day_of_week(month, d) == target_day }
  end

  private

  def normalize_year(year)
    return 0 unless year.is_a?(Integer)
    return 0 if year.negative?
    year
  end

  def valid_year?
    year.is_a?(Integer) && year >= 0
  end

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end
end