class Calendar
  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
      # Compute day of week for Jan 1 using Zeller's congruence
      q = 1
      m = 13
      year_temp = @year - 1
      K = year_temp % 100
      J = year_temp / 100
      h = (1 + (13*(m+1))/5 + K + K/4 + J/4 + 5*J) % 7
      @jan1_day = (h + 6) % 7
    else
      @year = nil
      @jan1_day = nil
    end
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return 0 if @year.nil? || month < 1 || month > 12
    if month == 2
      return 29 if is_leap_year?
      return 28
    elsif [4, 6, 9, 11].include?(month)
      return 30
    else
      return 31
    end
  end

  def day_of_week(month, day)
    return nil if @year.nil? || month.nil? || day.nil?
    return nil if month < 1 || month > 12
    return nil if day < 1 || day > days_in_month(month)
    
    total_days = 0
    (1...month).each { |m| total_days += days_in_month(m) }
    total_days += day - 1
    (@jan1_day + total_days) % 7
  end

  def get_month_name(month)
    return nil if month.nil? || month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return "Invalid Date" if @year.nil? || month.nil? || day.nil?
    return "Invalid Date" if month < 1 || month > 12 || day < 1 || day > days_in_month(month)
    "#{@year}-#{sprintf('%02d', month)}-#{sprintf('%02d', day)}"
  end

  def get_days_until_date(month, day)
    return nil if @year.nil? || month.nil? || day.nil?
    return nil if month < 1 || month > 12
    return nil if day < 1 || day > days_in_month(month)
    
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if @year.nil?
    return false if month.nil? || day.nil?
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] if @year.nil? || month.nil?
    return [] if month < 1 || month > 12
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if @year.nil? || month.nil? || target_day.nil?
    return 0 if month < 1 || month > 12
    return 0 if target_day < 0 || target_day > 6
    
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end