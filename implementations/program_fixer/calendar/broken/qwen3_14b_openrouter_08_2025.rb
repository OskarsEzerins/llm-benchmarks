class Calendar
  def initialize(year)
    @year = nil
    if year.is_a?(Integer) && year > 0
      @year = year
    end
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4 == 0) && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2
      return is_leap_year? ? 29 : 28
    end
    days[month - 1]
  end

  def day_of_week(month, day)
    m = month
    y = @year
    if m <= 2
      m += 12
      y -= 1
    end
    q = day
    K = y % 100
    J = y / 100
    h = q + (13 * (m + 1)) / 5 + K + (K / 4) + (J / 4) + 5 * J
    h = h % 7
    required_day = (h + 6) % 7
    required_day
  end

  def get_month_name(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total += day
    total
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    month_days = days_in_month(month)
    return false if day < 1 || day > month_days
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && target_day.is_a?(Integer)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end