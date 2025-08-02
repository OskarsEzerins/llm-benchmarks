# frozen_string_literal: true

class Calendar
  attr_reader :year

  def initialize(year)
    if year.is_a?(Integer) && year.positive?
      @year = year
    else
      @year = nil # Or raise an error, depending on desired behavior
    end
  end

  def is_leap_year?
    return false unless @year
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return nil unless @year # Handle uninitialized year
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    if month == 2 && is_leap_year?
      return 29
    end

    days[month - 1] # Correct array indexing for 1-based month
  end

  def day_of_week(month, day)
    return nil unless @year && is_valid_date?(month, day)

    # Ruby's Date class handles this reliably
    # January 1st, 0001 was a Monday based on proleptic Gregorian calendar
    # Zeller's congruence is another option for manual calculation
    # For simplicity and correctness, use Date.new
    begin
      date = Date.new(@year, month, day)
      date.wday # wday returns 0 for Sunday, 6 for Saturday
    rescue ArgumentError
      nil # Invalid date (e.g., Feb 30) will raise ArgumentError
    end
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12

    months = ["January", "February", "March", "April", "May", "June",
              "July", "August", "September", "October", "November", "December"]
    months[month - 1] # Correct array indexing for 1-based month
  end

  def format_date(month, day)
    return nil unless @year && is_valid_date?(month, day)

    # Use sprintf for consistent zero-padding
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless @year && is_valid_date?(month, day)

    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless @year
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12

    max_days = days_in_month(month)
    return false if max_days.nil? # Should not happen if month is valid, but for safety
    return false if day < 1 || day > max_days

    true
  end

  def get_weekdays_in_month(month)
    return [] unless @year && month.is_a?(Integer) && month >= 1 && month <= 12

    weekdays_list = []
    days_count = days_in_month(month)
    return [] if days_count.nil?

    day_names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    (1..days_count).each do |day|
      dow_index = day_of_week(month, day)
      weekdays_list << day_names[dow_index] if dow_index # Only add if day_of_week returns a valid index
    end

    weekdays_list
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless @year && month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6 # 0=Sun, 6=Sat

    count = 0
    days_count = days_in_month(month)
    return 0 if days_count.nil?

    (1..days_count).each do |day|
      count += 1 if day_of_week(month, day) == target_day
    end

    count
  end
end

require 'date' # Required for Date.new and Date.wday