# frozen_string_literal: true

class Calendar
  attr_reader :year

  MONTH_NAMES = ["January", "February", "March", "April", "May", "June",
                 "July", "August", "September", "October", "November", "December"].freeze

  WEEKDAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"].freeze

  def initialize(year)
    @year = (year.is_a?(Integer) && year > 0) ? year : 0
  end

  def is_leap_year?
    return false if @year == 0
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    month = month.to_i
    return 0 unless (1..12).include?(month)

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    if month == 2 && is_leap_year?
      29
    else
      days[month - 1]
    end
  end

  def day_of_week(month, day)
    month = month.to_i
    day = day.to_i
    return nil unless is_valid_date?(month, day)
    # Use Ruby's built-in Date class for correct day of week
    require 'date'
    Date.new(@year, month, day).wday
  rescue ArgumentError
    nil
  end

  def get_month_name(month)
    month = month.to_i
    return nil unless (1..12).include?(month)
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    month = month.to_i
    day = day.to_i
    return nil unless is_valid_date?(month, day)
    format("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    month = month.to_i
    day = day.to_i
    return nil unless is_valid_date?(month, day)

    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total + day - 1
  end

  def is_valid_date?(month, day)
    month = month.to_i
    day = day.to_i
    return false unless (1..12).include?(month)
    return false unless (1..days_in_month(month)).include?(day)
    true
  end

  def get_weekdays_in_month(month)
    month = month.to_i
    return [] unless (1..12).include?(month)

    weekdays = []
    days_count = days_in_month(month)

    (1..days_count).each do |day|
      day_name = WEEKDAY_NAMES[day_of_week(month, day)]
      weekdays << day_name
    end

    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    month = month.to_i
    target_day = target_day.to_i
    return 0 unless (1..12).include?(month)
    return 0 unless (0..6).include?(target_day)

    count = 0
    days_count = days_in_month(month)

    (1..days_count).each do |day|
      count += 1 if day_of_week(month, day) == target_day
    end

    count
  end
end