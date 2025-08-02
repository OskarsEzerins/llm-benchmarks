class Calendar
  MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze
  MONTH_NAMES = %w[January February March April May June July August September October November December].freeze
  WEEK_DAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  def initialize(year)
    @year = case year
            when NilClass, String, Integer
              year.to_i
            else
              raise ArgumentError, "Invalid year"
            end
    @year = 0 if @year.negative?
  end

  def is_leap_year?
    @year.zero? || ((@year % 4).zero? && (@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 29 if month == 2 && is_leap_year?
    MONTH_DAYS[month - 1]
  end

  def day_of_week(month, day)
    weeks = (1..month - 1).map { |m| MONTH_DAYS[m - 1] }.sum + day
    weeks += 1 if month > 2 && is_leap_year?
    weeks % 7
  end

  def get_month_name(month)
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    "#{year.to_s.rjust(4, '0')}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    total = 0
    (1...month).each { |m| total += MONTH_DAYS[m - 1] }
    total += day
    total
  end

  def is_valid_date?(month, day)
    return false unless (1..12).cover?(month)
    return false unless (1..days_in_month(month)).cover?(day)
    true
  end

  def get_weekdays_in_month(month)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      weekdays << WEEK_DAYS[day_of_week(month, d)]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end

  attr_reader :year
end