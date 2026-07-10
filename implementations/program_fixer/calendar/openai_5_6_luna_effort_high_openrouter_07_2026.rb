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
    @year = begin
      value = Integer(year)
      value >= 0 ? value : 0
    rescue ArgumentError, TypeError
      0
    end
  end

  def is_leap_year?
    @year > 0 && (@year % 4).zero? &&
      ((@year % 100) != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    offsets = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    year = @year
    year -= 1 if month < 3

    (year + year / 4 - year / 100 + year / 400 + offsets[month - 1] + day) % 7
  end

  def get_month_name(month)
    return nil unless valid_month?(month)

    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    (1...month).sum { |m| days_in_month(m) } + day - 1
  end

  def is_valid_date?(month, day)
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer)

    day.between?(1, days_in_month(month))
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month)

    (1..days_in_month(month)).map do |day|
      WEEKDAY_NAMES[day_of_week(month, day)]
    end
  end

  def count_occurrences_of_day(month, day_of_week)
    return 0 unless valid_month?(month)
    return 0 unless day_of_week.is_a?(Integer) && day_of_week.between?(0, 6)

    (1..days_in_month(month)).count do |day|
      self.day_of_week(month, day) == day_of_week
    end
  end

  private

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end
end