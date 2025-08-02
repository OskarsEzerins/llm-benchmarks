class Calendar
  def initialize(year)
    @year = year.to_i
  end

  def is_leap_year?
    (@year % 4).zero? && (@year % 100).nonzero? || (@year % 400).zero?
  end

  def days_in_month(month)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    total_days = 365 * (@year - 1) + (@year - 1) / 4 - (@year - 1) / 100 + (@year - 1) / 400
    total_days += [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334][month - 1]
    total_days += 1 if month > 2 && is_leap_year?
    total_days += day
    total_days % 7
  end

  def get_month_name(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    "#{@year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end
```