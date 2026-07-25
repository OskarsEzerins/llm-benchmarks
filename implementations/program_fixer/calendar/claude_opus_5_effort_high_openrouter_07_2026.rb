require 'date'

class Calendar
  MONTH_NAMES = %w[January February March April May June July August
                   September October November December].freeze

  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  DAYS_PER_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze

  attr_reader :year

  def initialize(year)
    @year = normalize_year(year)
  end

  def is_leap_year?
    return false if @year.nil?

    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    m = normalize_month(month)
    return nil if m.nil?

    return 29 if m == 2 && is_leap_year?

    DAYS_PER_MONTH[m - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    Date.new(@year, normalize_month(month), normalize_day(day)).wday
  end

  def get_month_name(month)
    m = normalize_month(month)
    return nil if m.nil?

    MONTH_NAMES[m - 1]
  end

  def get_day_name(month, day)
    wday = day_of_week(month, day)
    return nil if wday.nil?

    DAY_NAMES[wday]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format('%04d-%02d-%02d', @year, normalize_month(month), normalize_day(day))
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    m = normalize_month(month)
    d = normalize_day(day)

    total = 0
    (1...m).each { |mm| total += days_in_month(mm) }
    total + d - 1
  end

  def is_valid_date?(month, day)
    return false if @year.nil?

    m = normalize_month(month)
    return false if m.nil?

    d = normalize_day(day)
    return false if d.nil?

    d >= 1 && d <= days_in_month(m)
  end

  def get_weekdays_in_month(month)
    m = normalize_month(month)
    return [] if m.nil? || @year.nil?

    (1..days_in_month(m)).map do |d|
      DAY_NAMES[day_of_week(m, d)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    m = normalize_month(month)
    return 0 if m.nil? || @year.nil?

    target = normalize_day_of_week(target_day)
    return 0 if target.nil?

    count = 0
    (1..days_in_month(m)).each do |d|
      count += 1 if day_of_week(m, d) == target
    end
    count
  end

  private

  def normalize_year(value)
    case value
    when Integer
      value > 0 ? value : nil
    when Float
      value > 0 && value.finite? && value == value.to_i ? value.to_i : nil
    when String
      value.match?(/\A\s*\d+\s*\z/) && value.to_i > 0 ? value.to_i : nil
    else
      nil
    end
  end

  def to_integer(value)
    case value
    when Integer
      value
    when Float
      value.finite? && value == value.to_i ? value.to_i : nil
    when String
      value.match?(/\A\s*-?\d+\s*\z/) ? value.to_i : nil
    else
      nil
    end
  end

  def normalize_month(month)
    m = to_integer(month)
    return nil if m.nil?

    m.between?(1, 12) ? m : nil
  end

  def normalize_day(day)
    d = to_integer(day)
    return nil if d.nil?

    d >= 1 ? d : nil
  end

  def normalize_day_of_week(value)
    v = to_integer(value)
    return nil if v.nil?

    v.between?(0, 6) ? v : nil
  end
end