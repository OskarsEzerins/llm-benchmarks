class Calendar
  attr_reader :year

  WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze
  MONTH_NAMES = %w[January February March April May June July August September October November December].freeze

  def initialize(year)
    y =
      if year.is_a?(Integer)
        year
      elsif year.is_a?(String) && year.match?(/\A-?\d+\z/)
        year.to_i
      elsif year.respond_to?(:to_int)
        year.to_int
      elsif year.respond_to?(:to_i)
        year.to_i
      else
        nil
      end
    @year = y.is_a?(Integer) && y > 0 ? y : 2000
  end

  def is_leap_year?
    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    m = (month.to_i rescue nil)
    return 0 unless m.is_a?(Integer) && m.between?(1, 12)
    case m
    when 1, 3, 5, 7, 8, 10, 12
      31
    when 4, 6, 9, 11
      30
    when 2
      is_leap_year? ? 29 : 28
    else
      0
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    require 'date'
    Date.new(@year, month, day).wday
  rescue ArgumentError
    nil
  end

  def get_month_name(month)
    m = (month.to_i rescue nil)
    return nil unless m.is_a?(Integer) && m.between?(1, 12)
    MONTH_NAMES[m - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + (day - 1)
  end

  def is_valid_date?(month, day)
    m = (month.to_i rescue nil)
    d = (day.to_i rescue nil)
    return false unless m.is_a?(Integer) && d.is_a?(Integer)
    return false unless m.between?(1, 12)
    max_day = days_in_month(m)
    return false if max_day <= 0
    d.between?(1, max_day)
  end

  def get_weekdays_in_month(month)
    m = (month.to_i rescue nil)
    return [] unless m.is_a?(Integer) && m.between?(1, 12)
    days = days_in_month(m)
    return [] if days <= 0
    (1..days).map do |d|
      WEEKDAY_NAMES[day_of_week(m, d)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    m = (month.to_i rescue nil)
    t = (target_day.to_i rescue nil)
    return 0 unless m.is_a?(Integer) && m.between?(1, 12)
    return 0 unless t.is_a?(Integer) && t.between?(0, 6)
    count = 0
    (1..days_in_month(m)).each do |d|
      count += 1 if day_of_week(m, d) == t
    end
    count
  end
end