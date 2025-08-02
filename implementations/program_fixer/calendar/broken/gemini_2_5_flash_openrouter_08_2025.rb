class Calendar
  attr_reader :year

  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = nil # Or raise an error, depending on desired behavior
    end
  end

  def is_leap_year?
    return false unless @year
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless @year
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12

    days_map = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    
    if month == 2 && is_leap_year?
      29
    else
      days_map[month]
    end
  end

  def day_of_week(month, day)
    return nil unless @year
    return nil unless is_valid_date?(month, day)

    # Zeller's congruence
    # h = (q + floor(13*(m+1)/5) + K + floor(K/4) + floor(J/4) - 2*J) mod 7
    # q is the day of the month
    # m is the month (3=March, ..., 12=December, 1=January, 2=February)
    # K is the year of the century (year % 100)
    # J is the zero-based century (floor(year / 100))
    # For January and February, the year is counted as the previous year.

    m = month
    y = @year

    if m <= 2
      m += 12
      y -= 1
    end

    q = day
    K = y % 100
    J = y / 100

    h = (q + (13 * (m + 1)) / 5 + K + K / 4 + J / 4 - 2 * J) % 7
    (h + 6) % 7 # Adjust to 0=Sunday, 6=Saturday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless @year
    return nil unless is_valid_date?(month, day)

    "#{@year}-%02d-%02d" % [month, day]
  end

  def get_days_until_date(month, day)
    return nil unless @year
    return nil unless is_valid_date?(month, day)

    total_days = 0
    (1...month).each do |m|
      total_days += days_in_month(m)
    end
    total_days + day - 1 # -1 because we count from Jan 1st, not Jan 0th
  end

  def is_valid_date?(month, day)
    return false unless @year
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month >= 1 && month <= 12
    
    max_days = days_in_month(month)
    return false if max_days.nil? # Should not happen if month is valid
    
    day >= 1 && day <= max_days
  end

  def get_weekdays_in_month(month)
    return [] unless @year
    return [] unless days_in_month(month)

    weekdays = []
    day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    (1..days_in_month(month)).each do |d|
      dow = day_of_week(month, d)
      weekdays << day_names[dow] unless dow.nil?
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day_of_week)
    return 0 unless @year
    return 0 unless days_in_month(month)
    return 0 unless target_day_of_week.is_a?(Integer) && target_day_of_week >= 0 && target_day_of_week <= 6

    count = 0
    (1..days_in_month(month)).each do |d|
      dow = day_of_week(month, d)
      count += 1 if dow == target_day_of_week
    end
    count
  end
end