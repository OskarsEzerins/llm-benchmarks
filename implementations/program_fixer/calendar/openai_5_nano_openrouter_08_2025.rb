class Calendar
  def initialize(year)
    if year.is_a?(Integer)
      @year = year >= 0 ? year : nil
    else
      @year = nil
    end
  end

  attr_reader :year

  def valid_year?
    !@year.nil?
  end

  def is_leap_year?
    return false unless valid_year?
    y = @year
    (y % 4).zero? && ((y % 100).nonzero? || (y % 400).zero?)
  end

  def days_in_month(month)
    return nil unless valid_year?
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      29
    else
      days[month - 1]
    end
  end

  def day_of_week(month, day)
    return nil unless valid_year?
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    return nil unless month >= 1 && month <= 12
    dim = days_in_month(month)
    return nil unless dim && day >= 1 && day <= dim

    y = @year
    m = month
    d = day
    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    year_adj = y - (m < 3 ? 1 : 0)
    (year_adj + year_adj / 4 - year_adj / 100 + year_adj / 400 + t[m - 1] + d) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    names = %w[January February March April May June July August September October November December]
    names[month - 1]
  end

  def format_date(month, day)
    return nil unless valid_year?
    return nil unless month.is_a?(Integer) && day.is_a?(Integer)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless valid_year?
    return nil unless is_valid_date?(month, day)
    total_before = 0
    (1...month).each { |m| total_before += days_in_month(m) }
    day_of_year = total_before + day
    day_of_year - 1
  end

  def is_valid_date?(month, day)
    return false unless valid_year?
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month >= 1 && month <= 12
    dim = days_in_month(month)
    return false unless dim
    day >= 1 && day <= dim
  end

  def get_weekdays_in_month(month)
    return nil unless valid_year?
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    result = []
    (1..days_in_month(month)).each do |d|
      dow = day_of_week(month, d)
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][dow]
      result << name
    end
    result
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless valid_year?
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end