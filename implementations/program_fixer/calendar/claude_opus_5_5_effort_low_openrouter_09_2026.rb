require 'date'

class Calendar
  attr_reader :year

  MONTH_NAMES = %w[January February March April May June July August September October November December].freeze
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze
  DAYS_PER_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze

  def initialize(year)
    @year = normalize_year(year)
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_month?(month)
    return 29 if month == 2 && is_leap_year?
    DAYS_PER_MONTH[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless valid_month?(month)
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    format('%04d-%02d-%02d', @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer)
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      weekdays << DAY_NAMES[day_of_week(month, d)]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end

  private

  def valid_month?(month)
    month.is_a?(Integer) && month >= 1 && month <= 12
  end

  def normalize_year(year)
    value =
      case year
      when Integer then year
      when String then year.strip =~ /\A-?\d+\z/ ? year.to_i : nil
      when Float then year.to_i
      end
    value.is_a?(Integer) && value > 0 ? value : Time.now.year
  end
end