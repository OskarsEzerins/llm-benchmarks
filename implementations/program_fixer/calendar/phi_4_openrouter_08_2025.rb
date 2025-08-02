# frozen_string_literal: true

class Calendar
  attr_reader :year

  MONTHS_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  MONTH_NAMES = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ]
  WEEKDAYS = [
    "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
  ]

  def initialize(year)
    @year = validate_year(year)
  end

  def is_leap_year?
    return false unless @year

    (@year % 4).zero? && (!(@year % 100).zero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless month_valid?(month)

    month -= 1
    return MONTHS_DAYS[month] + 1 if month == 1 && is_leap_year?

    MONTHS_DAYS[month]
  end

  def day_of_week(month, day)
    return nil unless month_valid?(month) && day_valid?(month, day)

    # Zeller's Congruence algorithm
    m = month < 3 ? month + 12 : month
    y = month < 3 ? @year - 1 : @year
    q = day
    h = (q + ((13 * (m + 1)) / 5).floor + y + (y / 4).floor - (y / 100).floor + (y / 400).floor) % 7

    (h + 5) % 7
  end

  def get_month_name(month)
    MONTH_NAMES[month - 1] if month_valid?(month)
  end

  def format_date(month, day)
    return nil unless month_valid?(month) && day_valid?(month, day)

    "#{@year}-#{format('%02d', month)}-#{format('%02d', day)}"
  end

  def get_days_until_date(month, day)
    return nil unless month_valid?(month) && day_valid?(month, day)

    total_days = 0
    (1...month).each { |m| total_days += days_in_month(m) }
    total_days + day - 1
  end

  def is_valid_date?(month, day)
    month_valid?(month) && day_valid?(month, day)
  end

  def get_weekdays_in_month(month)
    return nil unless month_valid?(month)

    weekdays = []
    days_count = days_in_month(month)

    (1..days_count).each do |day|
      weekdays << WEEKDAYS[day_of_week(month, day)]
    end

    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless month_valid?(month) && target_day.between?(0, 6)

    count = 0
    days_count = days_in_month(month)

    (1..days_count).each do |day|
      count += 1 if day_of_week(month, day) == target_day
    end

    count
  end

  private

  def validate_year(year)
    return nil unless year.is_a?(Integer) && year > 0

    year
  end

  def month_valid?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end

  def day_valid?(month, day)
    return false unless day.is_a?(Integer)

    days_in_month = days_in_month(month)
    day.between?(1, days_in_month)
  end
end