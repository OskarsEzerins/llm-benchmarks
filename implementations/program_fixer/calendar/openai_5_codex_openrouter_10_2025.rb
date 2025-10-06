require 'date'

class Calendar
  attr_reader :year

  def initialize(year)
    @year = normalize_year(year)
  end

  def is_leap_year?
    ((@year % 4).zero? && !(@year % 100).zero?) || (@year % 400).zero?
  end

  def days_in_month(month)
    return nil unless valid_month?(month)

    case month
    when 1, 3, 5, 7, 8, 10, 12
      31
    when 4, 6, 9, 11
      30
    when 2
      is_leap_year? ? 29 : 28
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)

    Date.new(@year, month, day).wday
  end

  def get_month_name(month)
    return nil unless valid_month?(month)

    Date::MONTHNAMES[month]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)

    format('%<year>04d-%<month>02d-%<day>02d', year: @year, month: month, day: day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)

    target = Date.new(@year, month, day)
    (target - Date.new(@year, 1, 1)).to_i
  end

  def is_valid_date?(month, day)
    return false unless valid_month?(month)
    return false unless day.is_a?(Integer)
    return false if day < 1 || day > days_in_month(month)

    true
  end

  def get_weekdays_in_month(month)
    return [] unless valid_month?(month)

    (1..days_in_month(month)).map do |day|
      Date::DAYNAMES[day_of_week(month, day)]
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_month?(month)
    return 0 unless valid_day_of_week?(target_day)

    (1..days_in_month(month)).count do |day|
      day_of_week(month, day) == target_day
    end
  end

  private

  def normalize_year(year)
    return year if year.is_a?(Integer) && year.positive?

    if year.respond_to?(:to_i)
      candidate = year.to_i
      return candidate if candidate.positive?
    end

    Date.today.year
  end

  def valid_month?(month)
    month.is_a?(Integer) && (1..12).include?(month)
  end

  def valid_day_of_week?(day)
    day.is_a?(Integer) && (0..6).include?(day)
  end
end