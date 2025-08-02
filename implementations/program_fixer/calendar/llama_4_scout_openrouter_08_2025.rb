class Calendar
  def initialize(year)
    raise TypeError, 'Year must be an integer' unless year.is_a?(Integer)
    raise ArgumentError, 'Year must be a positive integer' if year.nil? || year < 1

    @year = year
  end

  def year
    @year
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless (1..12).include?(month)

    [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1] + (is_leap_year? && month == 2 ? 1 : 0)
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    @year - (month < 3 ? 1 : 0) + (@year - (month < 3 ? 1 : 0)) / 4 - (@year - (month < 3 ? 1 : 0)) / 100 + (@year - (month < 3 ? 1 : 0)) / 400 + t[month - 1] + day
  end

  def get_month_name(month)
    return nil unless (1..12).include?(month)

    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    "#{@year.to_s.rjust(4, '0')}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless (1..12).include?(month) && day.is_a?(Integer) && day >= 1

    days = days_in_month(month)
    return false unless days

    day <= days
  end

  def get_weekdays_in_month(month)
    return [] unless (1..12).include?(month)

    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d) % 7]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless (0..6).include?(target_day) && (1..12).include?(month)

    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end