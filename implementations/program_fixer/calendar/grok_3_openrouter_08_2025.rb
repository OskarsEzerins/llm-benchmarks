class Calendar
  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : 0
  end

  def year
    @year
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && (1..12).cover?(month)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    return 0 unless is_valid_date?(month, day)
    date = Date.new(@year, month, day)
    date.wday
  end

  def get_month_name(month)
    return "" unless month.is_a?(Integer) && (1..12).cover?(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return "" unless is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return 0 unless is_valid_date?(month, day)
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
    return [] unless month.is_a?(Integer) && (1..12).cover?(month)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      wday = day_of_week(month, d)
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][wday]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && (1..12).cover?(month)
    return 0 unless target_day.is_a?(Integer) && (0..6).cover?(target_day)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end