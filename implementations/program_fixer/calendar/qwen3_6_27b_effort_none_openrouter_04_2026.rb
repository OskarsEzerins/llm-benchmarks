class Calendar
  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : nil
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    return nil unless day.is_a?(Integer) && day >= 1
    return nil unless days_in_month(month) && day <= days_in_month(month)
    
    # Using Zeller's congruence or a known reference date
    # Reference: Jan 1, 2000 was a Saturday (6)
    # We'll calculate days from a known reference
    
    # Start from year 1 for simplicity with a known formula
    # Or use Ruby's Date class logic manually
    
    # Let's use a simple approach: count days from a known reference
    # Jan 1, 2000 = Saturday (day_of_week = 6)
    # But we need to handle any year
    
    # Using Tomohiko Sakamoto's algorithm
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    y = @year
    y -= 1 if month < 3
    (y + y / 4 - y / 100 + y / 400 + t[month - 1] + day) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    return nil unless day.is_a?(Integer) && day >= 1
    return nil unless days_in_month(month) && day <= days_in_month(month)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    return nil unless day.is_a?(Integer) && day >= 1
    return nil unless days_in_month(month) && day <= days_in_month(month)
    
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && month >= 1 && month <= 12
    return false unless day.is_a?(Integer) && day >= 1
    max_days = days_in_month(month)
    return false if max_days.nil? || day > max_days
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    weekdays = []
    num_days = days_in_month(month)
    return [] if num_days.nil?
    (1..num_days).each do |d|
      dow = day_of_week(month, d)
      next if dow.nil?
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][dow]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6
    count = 0
    num_days = days_in_month(month)
    return 0 if num_days.nil?
    (1..num_days).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end