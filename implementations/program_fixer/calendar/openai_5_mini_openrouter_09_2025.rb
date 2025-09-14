require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = begin
      Integer(year)
    rescue StandardError
      nil
    end
    # Treat non-positive years as invalid (store nil) to avoid surprising behavior
    @year = nil if @year.nil? || @year <= 0
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4).zero? && ((!@year % 100).zero? ? (@year % 400).zero? : true) rescue nil
  end

  def days_in_month(month)
    m = safe_month(month)
    return nil unless m
    return 29 if m == 2 && is_leap_year?
    [nil, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m]
  end

  def day_of_week(month, day)
    return nil if @year.nil?
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  rescue StandardError
    nil
  end

  def get_month_name(month)
    m = safe_month(month)
    return nil unless m
    Date::MONTHNAMES[m]
  end

  def format_date(month, day)
    return nil if @year.nil?
    return nil unless is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month.to_i, day.to_i)
  end

  def get_days_until_date(month, day)
    return nil if @year.nil?
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).yday - 1
  rescue StandardError
    nil
  end

  def is_valid_date?(month, day)
    return false if @year.nil?
    m = safe_month(month)
    d = safe_day(day)
    return false unless m && d
    Date.valid_date?(@year, m, d)
  end

  def get_weekdays_in_month(month)
    return [] if @year.nil?
    m = safe_month(month)
    return [] unless m
    dim = days_in_month(m)
    return [] unless dim
    (1..dim).map { |d| Date::DAYNAMES[Date.new(@year, m, d).wday] }
  rescue StandardError
    []
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if @year.nil?
    m = safe_month(month)
    return 0 unless m
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    dim = days_in_month(m)
    return 0 unless dim
    count = 0
    (1..dim).each do |d|
      count += 1 if Date.new(@year, m, d).wday == target_day
    end
    count
  rescue StandardError
    0
  end

  private

  def safe_month(month)
    return nil unless month
    m = Integer(month) rescue nil
    return nil unless m && m.between?(1, 12)
    m
  end

  def safe_day(day)
    return nil unless day
    d = Integer(day) rescue nil
    d
  end
end