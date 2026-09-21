class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) ? year : 0
  end

  def is_leap_year?
    return false unless @year.is_a?(Integer) && @year > 0

    (@year % 4).zero? && (@year % 100 != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?

    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    # Sakamoto's method: 0 = Sunday, 6 = Saturday
    offsets = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    y = @year
    y -= 1 if month < 3
    (y + y / 4 - y / 100 + y / 400 + offsets[month - 1] + day) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12

    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    '%04d-%02d-%02d' % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless @year.is_a?(Integer) && @year > 0
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12

    dim = days_in_month(month)
    return false if dim.nil?
    return false if day < 1 || day > dim

    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    return [] unless @year.is_a?(Integer) && @year > 0

    names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).map { |d| names[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6
    return 0 unless @year.is_a?(Integer) && @year > 0

    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end