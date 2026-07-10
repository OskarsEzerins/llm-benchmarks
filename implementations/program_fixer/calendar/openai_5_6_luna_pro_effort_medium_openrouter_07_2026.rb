class Calendar
  attr_reader :year

  MONTH_NAMES = %w[
    January February March April May June
    July August September October November December
  ].freeze

  WEEKDAY_NAMES = %w[
    Sunday Monday Tuesday Wednesday Thursday Friday Saturday
  ].freeze

  def initialize(year)
    @year = year.is_a?(Integer) && year >= 0 ? year : 0
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100) != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    offsets = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    adjusted_year = @year
    adjusted_year -= 1 if month < 3

    (adjusted_year + adjusted_year / 4 - adjusted_year / 100 +
      adjusted_year / 400 + offsets[month - 1] + day) % 7
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
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)

    days = days_in_month(month)
    !days.nil? && day.between?(1, days)
  end

  def get_weekdays_in_month(month)
    days = days_in_month(month)
    return [] if days.nil?

    (1..days).map { |day| WEEKDAY_NAMES[day_of_week(month, day)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    days = days_in_month(month)
    return 0 if days.nil?

    (1..days).count { |day| day_of_week(month, day) == target_day }
  end
end