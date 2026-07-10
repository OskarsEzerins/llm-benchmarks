class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year.positive? ? year : 0
  end

  def is_leap_year?
    return false unless valid_year?

    (@year % 4).zero? && ((@year % 100) != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?

    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    offsets = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    adjusted_year = month < 3 ? @year - 1 : @year

    (adjusted_year + (adjusted_year / 4) - (adjusted_year / 100) +
      (adjusted_year / 400) + offsets[month - 1] + day) % 7
  end

  def get_month_name(month)
    return nil unless valid_month?(month)

    %w[January February March April May June July August September October November December][month - 1]
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
    return false unless valid_year?
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer)

    day >= 1 && day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month) && valid_year?

    weekday_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).map do |day|
      weekday_names[day_of_week(month, day)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month) && valid_year?
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    (1..days_in_month(month)).count do |day|
      day_of_week(month, day) == target_day
    end
  end

  private

  def valid_year?
    @year.is_a?(Integer) && @year.positive?
  end

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end
end