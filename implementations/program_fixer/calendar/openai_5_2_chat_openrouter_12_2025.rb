class Calendar
  attr_reader :year

  MONTH_NAMES = %w[
    January February March April May June
    July August September October November December
  ].freeze

  WEEKDAY_NAMES = %w[
    Sunday Monday Tuesday Wednesday Thursday Friday Saturday
  ].freeze

  def initialize(year)
    @year =
      if year.is_a?(Integer) && year > 0
        year
      else
        0
      end
  end

  def is_leap_year?
    return false if @year <= 0
    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?

    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    # Zeller’s congruence (Gregorian calendar)
    m = month
    y = @year
    if m < 3
      m += 12
      y -= 1
    end

    k = y % 100
    j = y / 100

    h = (day + (13 * (m + 1)) / 5 + k + (k / 4) + (j / 4) + (5 * j)) % 7
    # Convert Zeller (0=Saturday) to 0=Sunday
    (h + 6) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    format('%04d-%02d-%02d', @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total + (day - 1)
  end

  def is_valid_date?(month, day)
    return false unless @year.is_a?(Integer) && @year > 0
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)

    dim = days_in_month(month)
    return false if dim.nil?

    day.between?(1, dim)
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)

    weekdays = []
    dim = days_in_month(month)
    return [] if dim.nil?

    (1..dim).each do |d|
      dow = day_of_week(month, d)
      weekdays << WEEKDAY_NAMES[dow] if dow
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    count = 0
    dim = days_in_month(month)
    return 0 if dim.nil?

    (1..dim).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end