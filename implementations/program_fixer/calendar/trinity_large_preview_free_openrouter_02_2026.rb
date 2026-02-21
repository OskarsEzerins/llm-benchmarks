class Calendar
  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = nil
    end
  end

  def is_leap_year?
    return false unless @year
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless @year && month.is_a?(Integer) && month >= 1 && month <= 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1] + (month == 2 && is_leap_year? ? 1 : 0)
  end

  def day_of_week(month, day)
    return nil unless @year && is_valid_date?(month, day)
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    year = @year - (month < 3 ? 1 : 0)
    (year + year / 4 - year / 100 + year / 400 + t[month - 1] + day) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless @year && is_valid_date?(month, day)
    "#{@year.to_s.rjust(4, '0')}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil unless @year && is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day
  end

  def is_valid_date?(month, day)
    return false unless @year && month.is_a?(Integer) && month >= 1 && month <= 12
    return false unless day.is_a?(Integer) && day >= 1 && day <= days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return nil unless @year && month.is_a?(Integer) && month >= 1 && month <= 12
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless @year && month.is_a?(Integer) && month >= 1 && month <= 12
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end