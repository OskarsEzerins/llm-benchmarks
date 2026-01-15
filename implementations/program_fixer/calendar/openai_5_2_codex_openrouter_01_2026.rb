class Calendar
  MONTH_NAMES = %w[January February March April May June July August September October November December]
  WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

  attr_reader :year

  def initialize(year)
    @year = 0
    begin
      y = Integer(year)
      @year = y if y > 0
    rescue
      @year = 0
    end
  end

  def is_leap_year?
    return false unless @year.is_a?(Integer) && @year > 0
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    month == 2 && is_leap_year? ? 29 : days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    y = @year
    m = month
    d = day
    if m <= 2
      m += 12
      y -= 1
    end
    k = y % 100
    j = y / 100
    h = (d + (13 * (m + 1)) / 5 + k + (k / 4) + (j / 4) + 5 * j) % 7
    (h + 6) % 7
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
    total + (day - 1)
  end

  def is_valid_date?(month, day)
    return false unless @year.is_a?(Integer) && @year > 0
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    dim = days_in_month(month)
    return false if dim.nil?
    day >= 1 && day <= dim
  end

  def get_weekdays_in_month(month)
    return [] unless @year.is_a?(Integer) && @year > 0
    dim = days_in_month(month)
    return [] if dim.nil?
    (1..dim).map { |d| WEEKDAY_NAMES[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless @year.is_a?(Integer) && @year > 0
    dim = days_in_month(month)
    return 0 if dim.nil?
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    count = 0
    (1..dim).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end