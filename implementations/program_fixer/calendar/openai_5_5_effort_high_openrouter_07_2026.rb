class Calendar
  MONTH_NAMES = %w[
    January February March April May June
    July August September October November December
  ].freeze

  WEEKDAY_NAMES = %w[
    Sunday Monday Tuesday Wednesday Thursday Friday Saturday
  ].freeze

  DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze

  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : 1
  end

  def is_leap_year?
    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 0 unless valid_month?(month)

    return 29 if month == 2 && is_leap_year?

    DAYS_IN_MONTH[month - 1]
  end

  def day_of_week(month, day)
    return -1 unless is_valid_date?(month, day)

    days_before_year = (@year - 1) * 365 + (@year - 1) / 4 - (@year - 1) / 100 + (@year - 1) / 400
    day_of_year = get_days_until_date(month, day) + 1

    (days_before_year + day_of_year) % 7
  end

  def get_month_name(month)
    return "" unless valid_month?(month)

    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return "" unless is_valid_date?(month, day)

    format("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return -1 unless is_valid_date?(month, day)

    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer)

    day >= 1 && day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month)

    (1..days_in_month(month)).map do |day|
      WEEKDAY_NAMES[day_of_week(month, day)]
    end
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

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end
end