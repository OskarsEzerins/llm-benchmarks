class Calendar
  def initialize(year)
    @year = year.to_i
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1] + (is_leap_year? && month == 2 ? 1 : 0)
  end

  def day_of_week(month, day)
    total_days = (month - 1) * 31 + day
    (total_days + (@year - 1) + ((@year - 1) / 4) - ((@year - 1) / 100) + ((@year - 1) / 400)) % 7
  end

  def get_month_name(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    "#{@year}-#{format('%02d', month)}-#{format('%02d', day)}"
  end

  def get_days_until_date(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    month.between?(1, 12) && day.between?(1, days_in_month(month))
  end

  def get_weekdays_in_month(month)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      weekday = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << weekday
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