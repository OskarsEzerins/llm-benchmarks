class Calendar
  attr_reader :year

  def initialize(year)
    @year = (year.is_a?(Numeric) && year > 0) ? year.to_i : 0
  end

  def is_leap_year?
    return false if @year <= 0
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && (1..12).include?(month)
    case month
    when 4, 6, 9, 11 then 30
    when 2 then is_leap_year? ? 29 : 28
    else 31
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    # Zeller's congruence or Ruby's Time/Date logic
    # 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    Time.new(@year, month, day).wday
  rescue
    nil
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && (1..12).include?(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + (day - 1)
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && (1..12).include?(month)
    days_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    result = []
    (1..days_in_month(month)).each do |d|
      wday_index = day_of_week(month, d)
      result << days_names[wday_index]
    end
    result
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && (1..12).include?(month)
    return 0 unless target_day.is_a?(Integer) && (0..6).include?(target_day)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end