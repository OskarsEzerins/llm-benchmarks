require 'date'

class Calendar
  attr_reader :year

  MONTHS = %w[January February March April May June July August September October November December].freeze
  WEEKDAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  def initialize(year_input)
    @year = begin
      y = Integer(year_input)
      y >= 1 ? y : nil
    rescue
      nil
    end
  end

  def is_leap_year?
    return false unless @year

    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless month
    begin
      month = Integer(month)
    rescue
      return nil
    end
    return nil unless (1..12).include?(month)

    days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[2] = 29 if is_leap_year?
    days[month]
  end

  def day_of_week(month, day)
    return nil unless month && day && @year
    begin
      month = Integer(month)
      day = Integer(day)
    rescue
      return nil
    end
    return nil unless (1..12).include?(month) && day >= 1
    dim = days_in_month(month)
    return nil unless dim && day <= dim

    dow(@year, month, day)
  end

  def get_month_name(month)
    return nil unless month
    begin
      month = Integer(month)
    rescue
      return nil
    end
    return nil unless (1..12).include?(month)

    MONTHS[month - 1]
  end

  def format_date(month, day)
    return nil unless month && day && @year
    begin
      month = Integer(month)
      day = Integer(day)
    rescue
      return nil
    end
    return nil unless is_valid_date?(month, day)

    "#{@year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil unless month && day && @year
    begin
      month = Integer(month)
      day = Integer(day)
    rescue
      return nil
    end
    return nil unless (1..12).include?(month) && day >= 1
    dim = days_in_month(month)
    return nil unless dim && day <= dim

    days = 0
    1.upto(month - 1) do |m|
      days += days_in_month(m)
    end
    days + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month && day && @year
    begin
      month = Integer(month)
      day = Integer(day)
    rescue
      return false
    end
    return false unless (1..12).include?(month) && day >= 1
    dim = days_in_month(month)
    return false unless dim && day <= dim

    true
  end

  def get_weekdays_in_month(month)
    return [] unless month && @year
    begin
      month = Integer(month)
    rescue
      return []
    end
    return [] unless (1..12).include?(month)
    dim = days_in_month(month)
    return [] unless dim

    weekdays = []
    1.upto(dim) do |d|
      dow_val = day_of_week(month, d)
      weekdays << WEEKDAYS[dow_val] if dow_val
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month && @year
    begin
      month = Integer(month)
    rescue
      return 0
    end
    return 0 unless (1..12).include?(month)
    dim = days_in_month(month)
    return 0 unless dim

    begin
      target_day = Integer(target_day)
    rescue
      return 0
    end
    return 0 unless (0..6).include?(target_day)

    count = 0
    1.upto(dim) do |d|
      dow_val = day_of_week(month, d)
      count += 1 if dow_val == target_day
    end
    count
  end

  private

  def dow(y, m, d)
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    yy = y - (m < 3 ? 1 : 0)
    (d + t[m - 1] + yy + (yy / 4).to_i - (yy / 100).to_i + (yy / 400).to_i) % 7
  end
end