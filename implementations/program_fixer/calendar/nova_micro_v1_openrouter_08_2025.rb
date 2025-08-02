class Calendar
  def initialize(year)
    @year = year.is_a?(Integer) && year.positive? ? year : nil
  end

  def is_leap_year?
    @year.nil? ? false : (@year % 4.zero? && ((@year % 100 != 0) || (@year % 400).zero?))
  end

  def days_in_month(month)
    return 0 if month.nil? || month < 1 || month > 12
    days = [31, is_leap_year? ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30]
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil if month.nil? || month < 1 || month > 12 || day.nil? || day < 1 || day > days_in_month(month)
    (Date.new(@year, month, day).wday + 7) % 7
  end

  def get_month_name(month)
    return nil if month.nil? || month < 1 || month > 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil if month.nil? || month < 1 || month > 12 || day.nil? || day < 1 || day > days_in_month(month)
    "#{@year}-#{format_two_digits(month)}-#{format_two_digits(day)}"
  end

  def get_days_until_date(month, day)
    return nil if month.nil? || month < 1 || month > 12 || day.nil? || day < 1 || day > days_in_month(month)
    total = 0
    (1..month).each do |m|
      total += days_in_month(m)
    end
    total - day
  end

  def is_valid_date?(month, day)
    return false if month.nil? || month < 1 || month > 12 || day.nil? || day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return nil if month.nil? || month < 1 || month > 12
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil if month.nil? || month < 1 || month > 12 || target_day.nil? || target_day < 0 || target_day > 6
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end

  private

  def format_two_digits(number)
    number.to_s.rjust(2, '0')
  end
end