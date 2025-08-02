# frozen_string_literal: true

class Calendar
  attr_reader :year

  MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze
  MONTH_NAMES = ["January", "February", "March", "April", "May", "June",
                 "July", "August", "September", "October", "November", "December"].freeze
  DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"].freeze

  def initialize(year)
    @year = validate_year(year)
  end

  def is_leap_year?
    @year % 4 == 0 && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return 29 if month == 2 && is_leap_year?
    MONTH_DAYS[month - 1]
  end

  def day_of_week(month, day)
    total_days = sum_days_up_to(month, day)
    total_days % 7
  end

  def get_month_name(month)
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total + day
  end

  def is_valid_date?(month, day)
    return false unless valid_month?(month)
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    weekdays = []
    days_count = days_in_month(month)

    (1..days_count).each do |day|
      weekdays << DAY_NAMES[day_of_week(month, day)]
    end

    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    count = 0
    days_count = days_in_month(month)

    (1..days_count).each do |day|
      count += 1 if day_of_week(month, day) == target_day
    end

    count
  end

  private

  def validate_year(year)
    if year.nil? || !year.is_a?(Integer)
      0
    elsif year < 0
      -year
    else
      year
    end
  end

  def valid_month?(month)
    month.is_a?(Integer) && month.between?(1, 12)
  end

  def sum_days_up_to(month, day)
    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total += day
    total
  end
end