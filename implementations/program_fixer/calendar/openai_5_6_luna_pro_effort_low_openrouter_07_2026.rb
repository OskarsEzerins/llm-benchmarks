class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year >= 0 ? year : 0
  end

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

    offsets = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    adjusted_year = @year - (month < 3 ? 1 : 0)
    (adjusted_year + adjusted_year / 4 - adjusted_year / 100 +
      adjusted_year / 400 + offsets[month - 1] + day) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && (1..12).include?(month)

    %w[
      January February March April May June
      July August September October November December
    ][month - 1]
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
    month.is_a?(Integer) &&
      day.is_a?(Integer) &&
      (1..12).include?(month) &&
      day.between?(1, days_in_month(month))
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && (1..12).include?(month)

    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).map { |day| names[day_of_week(month, day)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) &&
                    (1..12).include?(month) &&
                    target_day.is_a?(Integer) &&
                    (0..6).include?(target_day)

    (1..days_in_month(month)).count { |day| day_of_week(month, day) == target_day }
  end
end