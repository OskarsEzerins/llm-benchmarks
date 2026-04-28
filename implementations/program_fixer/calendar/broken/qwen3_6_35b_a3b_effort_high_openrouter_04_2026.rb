class Calendar
  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : nil
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4 == 0) && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return 0 if month.nil? || month < 1 || month > 12
    days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month]
  end

  def day_of_week(month, day)
    return nil if @year.nil? || month.nil? || day.nil? || month < 1 || month > 12 || day < 1
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4][month - 1]
    t += @year - (1 if month < 3 else 0)
    (t + day) % 7
  end

  def get_month_name(month)
    return nil if month.nil? || month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil if @year.nil? || month.nil? || day.nil?
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return 0 if !is_valid_date?(month, day)
    (1...month).sum { |m| days_in_month(m) } + day - 1
  end

  def is_valid_date?(month, day)
    return false if month.nil? || month < 1 || month > 12
    return false if day.nil? || day < 1
    day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] if month.nil? || month < 1 || month > 12
    days_count = days_in_month(month)
    result = []
    (1..days_count).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      result << name
    end
    result
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if month.nil? || month < 1 || month > 12
    count = 0
    days_count = days_in_month(month)
    (1..days_count).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end