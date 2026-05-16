class Calendar
  def initialize(year)
    @year = year.to_i rescue nil
    @year = nil if @year && @year < 0
  end

  def year
    @year
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4 == 0) && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return nil if month.nil? || month < 1 || month > 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil if month.nil? || day.nil? || month < 1 || month > 12 || day < 1
    return nil if day > days_in_month(month).to_i
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    y = @year
    y -= 1 if month < 3
    (y + y/4 - y/100 + y/400 + t[month - 1] + day) % 7
  end

  def get_month_name(month)
    return nil if month.nil? || month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil if month.nil? || day.nil? || month < 1 || month > 12 || day < 1
    return nil if day > days_in_month(month).to_i
    "#{@year.to_s.rjust(4, '0')}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil if month.nil? || day.nil? || month < 1 || month > 12 || day < 1
    return nil if day > days_in_month(month).to_i
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if month.nil? || day.nil?
    return false if month < 1 || month > 12
    return false if day < 1
    day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] if month.nil? || month < 1 || month > 12
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if month.nil? || target_day.nil? || month < 1 || month > 12
    return 0 if target_day < 0 || target_day > 6
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end