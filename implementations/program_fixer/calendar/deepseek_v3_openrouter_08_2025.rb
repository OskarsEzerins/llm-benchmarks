class Calendar
  def initialize(year)
    @year = year.to_i
    @year = 2024 if @year <= 0
  end

  def year
    @year
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil if month < 1 || month > 12
    days = [31, is_leap_year? ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil if !is_valid_date?(month, day)
    Time.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil if month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil if !is_valid_date?(month, day)
    "#{@year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil if !is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if month.nil? || day.nil?
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return nil if month < 1 || month > 12
    weekdays = []
    (1..days_in_month(month)).each do |d|
      weekday = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << weekday
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil if month < 1 || month > 12 || target_day < 0 || target_day > 6
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end