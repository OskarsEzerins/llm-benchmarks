class Calendar
  attr_reader :year

  def initialize(year)
    raise ArgumentError, "Invalid year" unless valid_year?(year)
    @year = year
  end

  def valid_year?(year)
    year.is_a?(Integer) && year > 0
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 0 if month.nil? || month < 1 || month > 12
    days = [0, 31, is_leap_year? ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    total_days = (1...month).sum { |m| days_in_month(m) } + day
    total_days % 7
  end

  def get_month_name(month)
    return nil if month.nil? || month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "#{@year}-#{format('%02d', month)}-#{format('%02d', day)}"
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = (1...month).sum { |m| days_in_month(m) } + day
    total
  end

  def is_valid_date?(month, day)
    return false if month.nil? || day.nil? || month < 1 || month > 12
    day > 0 && day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless (0..6).include?(target_day)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end