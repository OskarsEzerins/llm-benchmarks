class Calendar
  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = 0
    end
  end

  def year
    @year
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    return nil unless day.is_a?(Integer) && day.between?(1, days_in_month(month))

    m = month
    y = @year
    if m < 3
      m += 12
      y -= 1
    end

    k = y % 100
    j = y / 100
    h = (day + (13 * (m + 1)) / 5 + k + k / 4 + j / 4 - 2 * j) % 7
    (h + 6) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    return nil unless month.between?(1, 12)
    return nil unless day.between?(1, (days_in_month(month) || 0))
    "#{@year}-#{format('%02d', month)}-#{format('%02d', day)}"
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
    dim = days_in_month(month)
    return false if dim.nil?
    return false if day < 1 || day > dim
    true
  end

  def get_weekdays_in_month(month)
    weekdays = []
    dim = days_in_month(month)
    return weekdays unless dim
    (1..dim).each do |d|
      weekdays << %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    count = 0
    dim = days_in_month(month)
    return count unless dim
    (1..dim).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end