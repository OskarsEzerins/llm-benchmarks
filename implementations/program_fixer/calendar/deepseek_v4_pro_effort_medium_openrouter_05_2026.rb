class Calendar
  attr_reader :year

  def initialize(year)
    @year = if year.is_a?(Integer) && year > 0
              year
            else
              0
            end
  end

  def is_leap_year?
    (@year % 4 == 0) && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 29 if month == 2 && is_leap_year?
    days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month]
  end

  def day_of_week(month, day)
    # Tomohiko Sakamoto's algorithm
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    y = @year - (month < 3 ? 1 : 0)
    (y + y / 4 - y / 100 + y / 400 + t[month - 1] + day) % 7
  end

  def get_month_name(month)
    names = %w[January February March April May June July August September October November December]
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    names[month - 1]
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
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    days_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).map { |d| days_names[day_of_week(month, d)] }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end