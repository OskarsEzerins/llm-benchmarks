class Calendar
  def initialize(year)
    @year = if year.is_a?(Integer) && year > 0
              year
            else
              nil
            end
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4 == 0) && ((@year % 100 != 0) || (@year % 400 == 0))
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 if @year.nil?
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      29
    else
      days[month - 1]
    end
  end

  def day_of_week(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    return nil if month < 1 || month > 12 || day < 1 || day > days_in_month(month)
    return nil if @year.nil?

    y = @year
    m = month
    d = day
    if m < 3
      m += 12
      y -= 1
    end
    k = y % 100
    j = y / 100
    h = (d + (13 * (m + 1) / 5) + k + (k / 4) + (j / 4) + 5 * j) % 7
    (h + 6) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    return nil if month < 1 || month > 12 || day < 1 || day > days_in_month(month)
    return nil if @year.nil?
    format("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    return nil if month < 1 || month > 12 || day < 1 || day > days_in_month(month)
    return nil if @year.nil?
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    return [] if @year.nil?
    weekdays = []
    (1..days_in_month(month)).each do |d|
      dow = day_of_week(month, d)
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][dow]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && target_day.is_a?(Integer)
    return 0 if month < 1 || month > 12
    return 0 if @year.nil?
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end