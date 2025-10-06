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
    return 0 if month.nil? || month < 1 || month > 12
    
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    
    # Using Zeller's congruence algorithm
    m = month
    y = @year
    if m < 3
      m += 12
      y -= 1
    end
    k = y % 100
    j = y / 100
    h = (day + (13 * (m + 1)) / 5 + k + (k / 4) + (j / 4) - 2 * j) % 7
    (h + 6) % 7 # Convert to 0=Sunday, 6=Saturday
  end

  def get_month_name(month)
    return nil if month.nil? || month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "#{@year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if month.nil? || day.nil? || month < 1 || month > 12 || day < 1
    day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return [] unless (1..12).include?(month)
    
    weekdays = []
    (1..days_in_month(month)).each do |d|
      day_index = day_of_week(month, d)
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_index]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless (1..12).include?(month) && (0..6).include?(target_day)
    
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end