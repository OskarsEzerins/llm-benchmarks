class Calendar
  attr_reader :year

  MONTH_NAMES = %w[
    January February March April May June
    July August September October November December
  ].freeze

  WEEKDAY_NAMES = %w[
    Sunday Monday Tuesday Wednesday Thursday Friday Saturday
  ].freeze

  DAYS_IN_MONTH_COMMON = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze

  def initialize(year)
    @year = year.is_a?(Integer) && year.positive? ? year : 0
  end

  def is_leap_year?
    return false unless valid_year?

    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 0 unless valid_month?(month)

    return 29 if month == 2 && is_leap_year?

    DAYS_IN_MONTH_COMMON[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    offsets = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    y = @year
    y -= 1 if month < 3

    (y + y / 4 - y / 100 + y / 400 + offsets[month - 1] + day) % 7
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
    (1...month).each do |m|
      total += days_in_month(m)
    end

    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless valid_year?
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer)

    day >= 1 && day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month) && valid_year?

    weekdays = []
    (1..days_in_month(month)).each do |day|
      weekdays << WEEKDAY_NAMES[day_of_week(month, day)]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    count = 0
    (1..days_in_month(month)).each do |day|
      count += 1 if day_of_week(month, day) == target_day
    end
    count
  end

  private

  def valid_year?
    @year.is_a?(Integer) && @year.positive?
  end

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end
end