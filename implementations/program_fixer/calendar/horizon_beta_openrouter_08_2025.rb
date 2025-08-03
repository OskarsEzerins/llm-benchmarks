class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.is_a?(Integer) ? year.abs : 0
  end

  def is_leap_year?
    (@year % 4).zero? && ((@year % 100) != 0 || (@year % 400).zero?)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    case month
    when 1, 3, 5, 7, 8, 10, 12
      31
    when 4, 6, 9, 11
      30
    when 2
      is_leap_year? ? 29 : 28
    else
      0
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    Date.new(@year, month, day).wday
  rescue
    nil
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month.between?(1, 12)
    Date::MONTHNAMES[month]
  rescue
    nil
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month.between?(1, 12)
    max_day = days_in_month(month)
    return false if max_day <= 0
    day.between?(1, max_day)
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month.between?(1, 12)
    (1..days_in_month(month)).map do |d|
      w = day_of_week(month, d)
      %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][w]
    end
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month.between?(1, 12)
    return 0 unless target_day.is_a?(Integer) && target_day.between?(0, 6)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end