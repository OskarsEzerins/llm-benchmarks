class Calendar
  MONTH_NAMES = %w[
    January February March April May June
    July August September October November December
  ].freeze

  WEEKDAY_NAMES = %w[
    Sunday Monday Tuesday Wednesday Thursday Friday Saturday
  ].freeze

  def initialize(year)
    @year =
      begin
        value = Integer(year)
        value >= 0 ? value : 0
      rescue ArgumentError, TypeError
        0
      end
  end

  attr_reader :year

  def is_leap_year?
    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && (1..12).include?(month)

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    month_adjustment = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    adjusted_year = @year
    adjusted_year -= 1 if month < 3

    (adjusted_year + adjusted_year / 4 - adjusted_year / 100 +
      adjusted_year / 400 + month_adjustment[month - 1] + day) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && (1..12).include?(month)

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
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless (1..12).include?(month)

    maximum_day = days_in_month(month)
    day.between?(1, maximum_day)
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && (1..12).include?(month)

    (1..days_in_month(month)).map do |day|
      WEEKDAY_NAMES[day_of_week(month, day)]
    end
  end

  def count_occurrences_of_day(month, day_of_week)
    return 0 unless month.is_a?(Integer) && (1..12).include?(month)
    return 0 unless day_of_week.is_a?(Integer) && (0..6).include?(day_of_week)

    (1..days_in_month(month)).count do |day|
      self.day_of_week(month, day) == day_of_week
    end
  end
end