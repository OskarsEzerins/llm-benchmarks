class Calendar
  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : nil
  end

  def is_leap_year?
    return false unless @year
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless (1..12).cover?(month)
    days = [31, is_leap_year? ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    date = Date.new(@year, month, day)
    date.wday
  end

  def get_month_name(month)
    return nil unless (1..12).cover?(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "#{@year.to_s.rjust(4, '0')}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    date = Date.new(@year, month, day)
    date.yday - 1
  end

  def is_valid_date?(month, day)
    return false unless (1..12).cover?(month) && (1..31).cover?(day)
    days_in_month(month) >= day
  end

  def get_weekdays_in_month(month)
    return [] unless (1..12).cover?(month)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays.uniq
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless (1..12).cover?(month) && (0..6).cover?(target_day)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end