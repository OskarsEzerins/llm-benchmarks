class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) && year.positive? ? year : nil
  end

  def is_leap_year?
    return false unless valid_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    (days_from_civil(@year, month, day) + 4) % 7
  end

  def get_month_name(month)
    return nil unless valid_month?(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    format('%04d-%02d-%02d', @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless valid_year?
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless valid_month?(month)
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month) && valid_year?
    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).map { |d| names[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month) && valid_year?
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    (1..days_in_month(month)).count { |d| day_of_week(month, d) == target_day }
  end

  private

  def valid_year?
    @year.is_a?(Integer) && @year.positive?
  end

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end

  def days_from_civil(y, m, d)
    y -= 1 if m <= 2
    era = y / 400
    yoe = y - era * 400
    mp = (m + 9) % 12
    doy = (153 * mp + 2) / 5 + d - 1
    doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
    era * 146097 + doe - 719468
  end
end