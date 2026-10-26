class Calendar
  attr_reader :year

  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
      @valid_year = true
    else
      @year = 0
      @valid_year = false
    end
  end

  def is_leap_year?
    return false unless @valid_year
    (@year % 4).zero? && ((@year % 100) != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    return 29 if month == 2 && is_leap_year?
    [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    y = @year
    y -= 1 if month < 3
    (y + y / 4 - y / 100 + y / 400 + t[month - 1] + day) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless @valid_year
    return false unless month.is_a?(Integer) && month.between?(1, 12)
    return false unless day.is_a?(Integer)
    day.between?(1, days_in_month(month))
  end

  def get_weekdays_in_month(month)
    return [] unless @valid_year && month.is_a?(Integer) && month.between?(1, 12)
    day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).map { |d| day_names[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless @valid_year && month.is_a?(Integer) && month.between?(1, 12)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    (1..days_in_month(month)).count { |d| day_of_week(month, d) == target_day }
  end
end