# frozen_string_literal: true

class Calendar
  attr_reader :year

  def initialize(year)
    # Handle nil, String, or negative input
    if year.nil?
      @year = 0
    elsif year.is_a?(String)
      if year.to_i.to_s == year.strip
        @year = year.to_i
      else
        @year = 0
      end
    elsif year.is_a?(Numeric) && year >= 0
      @year = year.to_i
    else
      @year = 0
    end
  end

  def is_leap_year?
    (@year % 4 == 0) && ((@year % 100 != 0) || (@year % 400 == 0))
  end

  def days_in_month(month)
    month = month.to_i if month.respond_to?(:to_i)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      return 29
    end
    days[month - 1]
  end

  def day_of_week(month, day)
    month = month.to_i if month.respond_to?(:to_i)
    day = day.to_i if day.respond_to?(:to_i)
    return nil unless is_valid_date?(month, day)
    # Zeller's Congruence (0 = Saturday, 1 = Sunday, ..., 6 = Friday)
    y = @year
    m = month
    d = day
    if m < 3
      m += 12
      y -= 1
    end
    k = y % 100
    j = y / 100
    h = (d + ((13 * (m + 1)) / 5).to_i + k + (k / 4).to_i + (j / 4).to_i + 5 * j) % 7
    # Zeller's: 0=Saturday, 1=Sunday, ..., 6=Friday
    # We want: 0=Sunday, 1=Monday, ..., 6=Saturday
    ((h + 6) % 7)
  end

  def get_month_name(month)
    month = month.to_i if month.respond_to?(:to_i)
    months = ["January", "February", "March", "April", "May", "June",
              "July", "August", "September", "October", "November", "December"]
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    months[month - 1]
  end

  def format_date(month, day)
    month = month.to_i if month.respond_to?(:to_i)
    day = day.to_i if day.respond_to?(:to_i)
    return nil unless is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    month = month.to_i if month.respond_to?(:to_i)
    day = day.to_i if day.respond_to?(:to_i)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total + (day - 1)
  end

  def is_valid_date?(month, day)
    month = month.to_i if month.respond_to?(:to_i)
    day = day.to_i if day.respond_to?(:to_i)
    return false unless month.is_a?(Integer) && month >= 1 && month <= 12
    return false unless day.is_a?(Integer) && day >= 1 && day <= days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    month = month.to_i if month.respond_to?(:to_i)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    weekdays = []
    days_count = days_in_month(month)
    day_names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    (1..days_count).each do |day|
      dow = day_of_week(month, day)
      weekdays << day_names[dow] if dow
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    month = month.to_i if month.respond_to?(:to_i)
    target_day = target_day.to_i if target_day.respond_to?(:to_i)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6
    count = 0
    days_count = days_in_month(month)
    (1..days_count).each do |day|
      count += 1 if day_of_week(month, day) == target_day
    end
    count
  end
end