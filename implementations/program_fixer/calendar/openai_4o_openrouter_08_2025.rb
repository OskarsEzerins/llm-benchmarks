class Calendar
  def initialize(year)
    @year = year.is_a?(Integer) && year > 0 ? year : nil
  end
  
  def year
    @year
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4).zero? && ((@year % 100).nonzero? || (@year % 400).zero?)
  end

  def days_in_month(month)
    return nil unless (1..12).include?(month)
    days = [31, (is_leap_year? ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[month - 1]
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    # Zeller's Congruence algorithm to compute day of week
    m = month < 3 ? month + 12 : month
    y = month < 3 ? @year - 1 : @year
    k = y % 100
    j = y / 100
    h = (day + (13 * (m + 1)) / 5 + k + k / 4 + j / 4 + 5 * j) % 7
    (h + 5) % 7 # Adjusting to make 0=Sunday, 6=Saturday
  end

  def get_month_name(month)
    return nil unless (1..12).include?(month)
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless (1..12).include?(month) && day.is_a?(Integer) && day > 0
    day <= days_in_month(month)
  end

  def get_weekdays_in_month(month)
    return nil unless (1..12).include?(month)
    weekdays = []
    (1..days_in_month(month)).each do |d|
      name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless (0..6).include?(target_day) && (1..12).include?(month)
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end