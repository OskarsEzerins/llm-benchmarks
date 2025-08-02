class Calendar
  attr_reader :year

  def initialize(year)
    @year = year if year.is_a?(Integer) && year.positive?
  end

  def is_leap_year?
    return false if @year.nil?
    y = @year
    (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && (1..12).cover?(month)
    days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month]
    days += 1 if month == 2 && is_leap_year?
    days
  end

  def day_of_week(month, day)
    return nil if @year.nil? || !is_valid_date?(month, day)
    y = @year
    m = month
    d = day
    if m < 3
      m += 12
      y -= 1
    end
    k = y % 100
    j = y / 100
    h = (d + (13 * (m + 1)) / 5 + k + (k / 4) + (j / 4) + 5 * j) % 7
    ((h - 1) % 7)
  end

  def get_month_name(month)
    names = %w[January February March April May June July August September October November December]
    return nil unless month.is_a?(Integer) && (1..12).cover?(month)
    names[month - 1]
  end

  def format_date(month, day)
    return nil if @year.nil? || !is_valid_date?(month, day)
    "#{@year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil if @year.nil? || !is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if @year.nil?
    return false unless month.is_a?(Integer) && (1..12).cover?(month)
    return false unless day.is_a?(Integer) && (1..days_in_month(month)).cover?(day)
    true
  end

  def get_weekdays_in_month(month)
    return [] if @year.nil? || !month.is_a?(Integer) || !(1..12).cover?(month)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, day_of_week)
    return 0 if @year.nil? || !month.is_a?(Integer) || !(1..12).cover?(month)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == day_of_week
    end
    count
  end
end