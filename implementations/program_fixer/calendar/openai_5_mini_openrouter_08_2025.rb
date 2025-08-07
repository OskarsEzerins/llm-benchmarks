require 'date'

class Calendar
  attr_reader :year

  MONTH_NAMES = [nil, "January", "February", "March", "April", "May", "June",
                 "July", "August", "September", "October", "November", "December"].freeze

  WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  def initialize(year)
    @year = if year.respond_to?(:to_i)
              year.to_i
            else
              0
            end
  end

  def is_leap_year?
    return false unless @year.is_a?(Integer)
    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)

    return 29 if month == 2 && is_leap_year?

    case month
    when 1 then 31
    when 2 then 28
    when 3 then 31
    when 4 then 30
    when 5 then 31
    when 6 then 30
    when 7 then 31
    when 8 then 31
    when 9 then 30
    when 10 then 31
    when 11 then 30
    when 12 then 31
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  rescue ArgumentError
    nil
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    MONTH_NAMES[month]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).yday - 1
  rescue ArgumentError
    nil
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    return false if day < 1
    dim = days_in_month(month)
    return false if dim.nil?
    day <= dim
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)
    dim = days_in_month(month)
    return [] if dim.nil? || dim <= 0
    (1..dim).map do |d|
      w = day_of_week(month, d)
      WEEKDAY_NAMES[w] if w
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    dim = days_in_month(month)
    return 0 if dim.nil? || dim <= 0
    count = 0
    (1..dim).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end