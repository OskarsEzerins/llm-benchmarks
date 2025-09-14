class Calendar
  def initialize(year)
    if year.nil? || !year.is_a?(Integer) || year <= 0
      @year = nil
    else
      @year = year
    end
  end

  def year
    @year
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 0 if @year.nil?
    days = [0, 31, is_leap_year? ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    y = @year
    m = month
    d = day
    if m < 3
      m += 12
      y -= 1
    end
    day_of = (d + (13 * (m + 1)) / 5 + y + (y / 4) - (y / 100) + (y / 400)).to_i % 7
    (day_of + 6) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "#{@year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1..month-1).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && month.between?(1, 12)
    return false unless day.is_a?(Integer) && day.between?(1, days_in_month(month))
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, day_of_week)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12) && day_of_week.is_a?(Integer) && day_of_week.between?(0, 6)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == day_of_week
    end
    count
  end
end