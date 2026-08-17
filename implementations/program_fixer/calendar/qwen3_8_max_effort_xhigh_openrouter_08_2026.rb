class Calendar
  attr_reader :year

  MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze
  MONTH_NAMES = %w[January February March April May June July August September October November December].freeze
  WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze
  DAY_TABLE = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4].freeze

  def initialize(year)
    parsed = integer_or_nil(year)

    if parsed.nil? || !parsed.is_a?(Integer) || parsed < 0
      @year = 0
      @valid_year = false
    else
      @year = parsed
      @valid_year = true
    end
  end

  def is_leap_year?
    return false unless valid_year?

    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    m = normalize_month(month)
    return nil unless m

    return 29 if m == 2 && is_leap_year?

    MONTH_DAYS[m - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    m = normalize_month(month)
    d = integer_or_nil(day)
    return nil unless m && d

    y = @year
    y -= 1 if m < 3

    (y + y / 4 - y / 100 + y / 400 + DAY_TABLE[m - 1] + d) % 7
  end

  def get_month_name(month)
    m = normalize_month(month)
    return nil unless m

    MONTH_NAMES[m - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    m = normalize_month(month)
    d = integer_or_nil(day)
    return nil unless m && d

    format('%04d-%02d-%02d', @year, m, d)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    m = normalize_month(month)
    d = integer_or_nil(day)
    return nil unless m && d

    total = d - 1

    (1...m).each { |month_number| total += days_in_month(month_number) || 0 }
    total
  end

  def is_valid_date?(month, day)
    return false unless valid_year?

    m = normalize_month(month)
    return false unless m

    d = integer_or_nil(day)
    return false unless d

    dim = days_in_month(m)
    return false unless dim

    d.between?(1, dim)
  end

  def get_weekdays_in_month(month)
    m = normalize_month(month)
    dim = days_in_month(m)
    return [] unless valid_year? && m && dim

    weekdays = []

    (1..dim).each do |d|
      dow = day_of_week(m, d)
      weekdays << WEEKDAY_NAMES[dow] if dow
    end

    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    m = normalize_month(month)
    dim = days_in_month(m)
    target = integer_or_nil(target_day)

    return 0 unless valid_year? && m && dim && target && target.between?(0, 6)

    (1..dim).count { |d| day_of_week(m, d) == target }
  end

  private

  def valid_year?
    @valid_year && @year.is_a?(Integer) && @year >= 0
  end

  def integer_or_nil(value)
    return value if value.is_a?(Integer)
    return nil if value.nil? || value.is_a?(TrueClass) || value.is_a?(FalseClass)

    if value.is_a?(String)
      Integer(value)
    elsif value.respond_to?(:to_i)
      value.to_i
    end
  rescue StandardError
    nil
  end

  def normalize_month(month)
    m = integer_or_nil(month)
    return nil unless m && m.between?(1, 12)

    m
  end
end