class Calendar
  def initialize(year)
    @year = year.to_i if year.is_a?(Integer) || year.is_a?(String) && year =~ /^\d+$/
    @year = nil if @year <= 0
  end

  def year
    @year
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil if month.nil? || month < 1 || month > 12
    days = [31, is_leap_year? ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil if month.nil? || day.nil? || !is_valid_date?(month, day)
    date = Date.new(@year, month, day)
    date.wday
  end

  def get_month_name(month)
    return nil if month.nil? || month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil if month.nil? || day.nil? || !is_valid_date?(month, day)
    sprintf('%04d-%02d-%02d', @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil if month.nil? || day.nil? || !is_valid_date?(month, day)
    date = Date.new(@year, month, day)
    (date - Date.new(@year, 1, 1)).to_i
  end

  def is_valid_date?(month, day)
    return false if month.nil? || day.nil? || month < 1 || month > 12 || day < 1
    day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return nil if month.nil? || month < 1 || month > 12
    weekdays = []
    (1..days_in_month(month)).each do |d|
      next unless (1..7).cover?(day_of_week(month, d))
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil if month.nil? || target_day.nil? || month < 1 || month > 12 || target_day < 0 || target_day > 6
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end