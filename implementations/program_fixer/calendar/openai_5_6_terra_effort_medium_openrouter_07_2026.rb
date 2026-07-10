class Calendar
  attr_reader :year

  MONTH_NAMES = [
    "January", "February", "March", "April",
    "May", "June", "July", "August",
    "September", "October", "November", "December"
  ].freeze

  WEEKDAY_NAMES = [
    "Sunday", "Monday", "Tuesday", "Wednesday",
    "Thursday", "Friday", "Saturday"
  ].freeze

  def initialize(year)
    @year = year.is_a?(Integer) && year.positive? ? year : 0
  end

  def is_leap_year?
    return false if @year <= 0

    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)

    case month
    when 2
      is_leap_year? ? 29 : 28
    when 4, 6, 9, 11
      30
    else
      31
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    days_before_year = (@year - 1) * 365 +
                       ((@year - 1) / 4) -
                       ((@year - 1) / 100) +
                       ((@year - 1) / 400)

    days_before_month = (1...month).sum { |m| days_in_month(m) }

    (days_before_year + days_before_month + day) % 7
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
    return false unless @year.positive?
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer)

    day.between?(1, days_in_month(month))
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month) && @year.positive?

    (1..days_in_month(month)).map do |day|
      WEEKDAY_NAMES[day_of_week(month, day)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    return 0 unless @year.positive?

    (1..days_in_month(month)).count do |day|
      day_of_week(month, day) == target_day
    end
  end

  private

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end
end