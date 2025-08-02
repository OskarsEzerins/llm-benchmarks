class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.to_i if year.is_a?(Integer) && year.positive?
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(month, day)
    total_days = (1..month - 1).sum { |m| days_in_month(m) } + day
    (total_days + 1) % 7
  end

  def get_month_name(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return unless is_valid_date?(month, day)

    "#{@year}-#{format('%02d', month)}-#{format('%02d', day)}"
  end

  def get_days_until_date(month, day)
    return 0 unless is_valid_date?(month, day)

    total = (1..month - 1).sum { |m| days_in_month(m) }
    total + day
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless (1..12).cover?(month) && (1..days_in_month(month)).cover?(day)

    true
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
    count = (1..days_in_month(month)).count { |d| day_of_week(month, d) == target_day }
    count
  end
end