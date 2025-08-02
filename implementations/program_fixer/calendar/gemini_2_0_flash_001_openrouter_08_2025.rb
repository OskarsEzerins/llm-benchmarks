class Calendar
  def initialize(year)
    @year = year.to_i if year.is_a?(Numeric) && year.to_i.positive?
    @year = nil unless @year.is_a?(Integer)
  end

  def year
    @year
  end

  def is_leap_year?
    return false unless @year

    (@year % 4 == 0) && ((@year % 100 != 0) || (@year % 400 == 0))
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && (1..12).include?(month)
    return 29 if month == 2 && is_leap_year?

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless @year && month.is_a?(Integer) && day.is_a?(Integer)
    return nil unless is_valid_date?(month, day)

    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && (1..12).include?(month)

    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless @year && month.is_a?(Integer) && day.is_a?(Integer)
    return nil unless is_valid_date?(month, day)

    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless @year && month.is_a?(Integer) && day.is_a?(Integer)
    return nil unless is_valid_date?(month, day)

    Date.new(@year, month, day).yday - 1
  end

  def is_valid_date?(month, day)
    return false unless @year && month.is_a?(Integer) && day.is_a?(Integer)
    return false unless (1..12).include?(month)
    return false unless (1..31).include?(day)

    max_days = days_in_month(month)
    return false if max_days.nil? || day > max_days

    true
  end

  def get_weekdays_in_month(month)
    return nil unless month.is_a?(Integer) && (1..12).include?(month)

    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless month.is_a?(Integer) && (1..12).include?(month)
    return 0 unless target_day.is_a?(Integer) && (0..6).include?(target_day)

    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end