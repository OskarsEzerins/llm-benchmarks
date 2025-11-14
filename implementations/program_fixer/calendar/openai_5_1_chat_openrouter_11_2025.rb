class Calendar
  MONTH_NAMES = %w[January February March April May June July August September October November December]
  DAYS_IN_MONTH = {
    1 => 31, 2 => 28, 3 => 31, 4 => 30,
    5 => 31, 6 => 30, 7 => 31, 8 => 31,
    9 => 30, 10 => 31, 11 => 30, 12 => 31
  }

  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : 0
  end

  def year
    @year
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100) != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 29 if month == 2 && is_leap_year?
    DAYS_IN_MONTH[month]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    date = Date.new(@year, month, day)
    date.wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    (Date.new(@year, month, day) - Date.new(@year, 1, 1)).to_i
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    return false unless day.between?(1, days_in_month(month))
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)
    (1..days_in_month(month)).map do |d|
      Date::DAYNAMES[day_of_week(month, d)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    (1..days_in_month(month)).count { |d| day_of_week(month, d) == target_day }
  end
end