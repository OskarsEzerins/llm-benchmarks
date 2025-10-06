class Calendar
  def initialize(year_input)
    @year = nil
    if year_input.is_a?(Integer) && year_input > 0
      @year = year_input
    elsif year_input.respond_to?(:to_i)
      y = year_input.to_i
      @year = y if y > 0
    end
  end

  def year
    @year
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4 == 0 && (@year % 100 != 0 || @year % 400 == 0))
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return 29 if month == 2 && is_leap_year?
    days[month - 1]
  end

  def day_of_week(m, d)
    return nil if @year.nil? || m.nil? || d.nil?
    m = m.to_i
    d = d.to_i
    return nil if m < 1 || m > 12 || d < 1 || d > days_in_month(m).to_i
    mm = m
    yy = @year
    if mm <= 2
      yy -= 1
      mm += 12
    end
    k = yy % 100
    j = yy / 100
    h = (d + (13 * (mm + 1) / 5).floor + k + (k / 4).floor + (j / 4).floor + 5 * j) % 7
    (h + 6) % 7
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil if @year.nil?
    month = month.to_i
    day = day.to_i
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil if @year.nil? || month.nil? || day.nil?
    month = month.to_i
    day = day.to_i
    return nil if month < 1 || month > 12 || day < 1
    total = 0
    (1...month).each do |m|
      dm = days_in_month(m)
      total += dm if dm
    end
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month && day
    month = month.to_i
    day = day.to_i
    return false if month < 1 || month > 12 || day < 1
    dim = days_in_month(month)
    return false unless dim && day <= dim
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12
    weekdays = []
    num_days = days_in_month(month)
    return [] if num_days.nil?
    (1..num_days).each do |d|
      dow = day_of_week(month, d)
      if dow
        name = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][dow]
        weekdays << name
      end
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12 && target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6
    count = 0
    num_days = days_in_month(month)
    return 0 if num_days.nil?
    (1..num_days).each do |d|
      if day_of_week(month, d) == target_day
        count += 1
      end
    end
    count
  end
end