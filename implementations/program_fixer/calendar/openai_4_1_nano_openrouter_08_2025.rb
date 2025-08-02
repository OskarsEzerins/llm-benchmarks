class Calendar
  attr_reader :year

  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = nil
    end
  end

  def is_leap_year?
    return false unless year.is_a?(Integer)
    (year % 4).zero? && ((year % 100).nonzero? || (year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      29
    else
      days[month - 1]
    end
  end

  def day_of_week(month, day)
    return nil unless valid_date?(month, day)
    total_days = 0
    (1...month).each { |m| total_days += days_in_month(m) }
    total_days += day
    # Jan 1, 2024 is Monday (1), but since 2024 starts on Monday, adjust accordingly
    # We'll use Zeller's Congruence for accuracy
    y = year
    m = month
    d = day
    m = 13 if m == 1 || m == 2
    y -= 1 if m > 12
    k = y % 100
    j = y / 100
    q = d
    m = m
    h = (q + ((13 * (m + 1)) / 5).floor + k + (k / 4).floor + (j / 4).floor + 5 * j) % 7
    # h: 0=Saturday, 1=Sunday, 2=Monday, ..., 6=Friday
    # Adjust to 0=Sunday
    ((h + 6) % 7)
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    months = %w[January February March April May June July August September October November December]
    months[month - 1]
  end

  def format_date(month, day)
    return nil unless valid_date?(month, day)
    "#{year}-#{format('%02d', month)}-#{format('%02d', day)}"
  end

  def get_days_until_date(month, day)
    return nil unless valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    return false unless day.between?(1, days_in_month(month))
    true
  end

  def get_weekdays_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    return nil unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end

  private

  def valid_date?(month, day)
    is_valid_date?(month, day)
  end
end