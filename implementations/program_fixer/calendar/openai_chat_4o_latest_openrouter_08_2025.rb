require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = 0
    end
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 0 unless valid_month?(month)

    case month
    when 2
      is_leap_year? ? 29 : 28
    when 4, 6, 9, 11
      30
    else
      31
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    Date.new(@year, month, day).wday
  rescue
    nil
  end

  def get_month_name(month)
    return nil unless valid_month?(month)

    Date::MONTHNAMES[month]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    start_date = Date.new(@year, 1, 1)
    target_date = Date.new(@year, month, day)
    (target_date - start_date).to_i
  rescue
    nil
  end

  def is_valid_date?(month, day)
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer) && day >= 1 && day <= days_in_month(month)

    true
  rescue
    false
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month)

    weekdays = []
    (1..days_in_month(month)).each do |day|
      wday = day_of_week(month, day)
      weekdays << Date::DAYNAMES[wday] if wday
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)

    count = 0
    (1..days_in_month(month)).each do |day|
      count += 1 if day_of_week(month, day) == target_day
    end
    count
  end

  private

  def valid_month?(month)
    month.is_a?(Integer) && month >= 1 && month <= 12
  end
end