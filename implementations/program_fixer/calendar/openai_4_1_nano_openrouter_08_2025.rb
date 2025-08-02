# frozen_string_literal: true

class Calendar
  attr_reader :year

  def initialize(year)
    if year.is_a?(Numeric) && year.to_i > 0
      @year = year.to_i
    else
      @year = nil
    end
  end

  def is_leap_year?
    return false unless @year.is_a?(Integer)
    (@year % 4 == 0 && (@year % 100 != 0 || @year % 400 == 0))
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      return 29
    end
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless valid_date?(month, day)
    # Zeller's Congruence algorithm for Gregorian calendar
    m = month
    y = @year
    if m < 3
      m += 12
      y -= 1
    end
    k = y % 100
    j = y / 100
    h = (day + ((13 * (m + 1)) / 5).floor + k + (k / 4).floor + (j / 4).floor + 5 * j) % 7
    # h=0: Saturday, so to match Sunday=0, shift:
    (h + 6) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    months = ["January", "February", "March", "April", "May", "June",
              "July", "August", "September", "October", "November", "December"]
    months[month - 1]
  end

  def format_date(month, day)
    return nil unless valid_date?(month, day)
    year_str = @year.to_s.rjust(4, '0')
    month_str = month.to_s.rjust(2, '0')
    day_str = day.to_s.rjust(2, '0')
    "#{year_str}-#{month_str}-#{day_str}"
  end

  def get_days_until_date(month, day)
    return nil unless valid_date?(month, day)
    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month >= 1 && month <= 12
    max_day = days_in_month(month)
    return false unless max_day && day >= 1 && day <= max_day
    true
  end

  def get_weekdays_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    weekdays = []
    days_count = days_in_month(month)
    (1..days_count).each do |day|
      day_name = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
      weekdays << day_name[day_of_week(month, day)]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && target_day.is_a?(Integer)
    return 0 unless month >= 1 && month <= 12
    return 0 unless target_day >= 0 && target_day <= 6
    count = 0
    days_count = days_in_month(month)
    (1..days_count).each do |day|
      count += 1 if day_of_week(month, day) == target_day
    end
    count
  end

  private

  def valid_date?(month, day)
    is_valid_date?(month, day)
  end
end