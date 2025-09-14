class Calendar
  def initialize(year)
    @year = if year.respond_to?(:to_i)
              i = year.to_i
              i > 0 ? i : nil
            else
              nil
            end
  end

  def year
    @year
  end

  def is_leap_year?
    return false if @year.nil? || @year < 1
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return nil if @year.nil?
    month = month.to_i
    return nil if month < 1 || month > 12
    days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    d = days[month]
    d = 29 if month == 2 && is_leap_year?
    d
  end

  def day_of_week(month, day)
    return nil if @year.nil?
    month = month.to_i
    day = day.to_i
    return nil if month < 1 || month > 12 || day < 1
    dim = days_in_month(month)
    return nil if dim.nil? || day > dim
    doy = day
    (1...month).each { |m| doy += days_in_month(m) }
    y = @year
    days_since_epoch = (y - 1) * 365 + (y - 1) / 4 - (y - 1) / 100 + (y - 1) / 400
    dow_jan1 = ((days_since_epoch % 7) + 1) % 7
    ((dow_jan1 + doy - 1) % 7)
  end

  def get_month_name(month)
    month = month.to_i
    return nil if month < 1 || month > 12
    %w(January February March April May June July August September October November December)[month]
  end

  def format_date(month, day)
    return nil if @year.nil?
    month = month.to_i
    day = day.to_i
    "#{@year.to_s.rjust(4, '0')}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def get_days_until_date(month, day)
    return nil if @year.nil?
    month = month.to_i
    day = day.to_i
    return nil if month < 1 || month > 12 || day < 1
    dim = days_in_month(month)
    return nil if dim.nil? || day > dim
    total = 0
    (1...month).each do |m|
      dm = days_in_month(m)
      return nil if dm.nil?
      total += dm
    end
    total + (day - 1)
  end

  def is_valid_date?(month, day)
    return false if @year.nil?
    month = month.to_i
    day = day.to_i
    return false if month < 1 || month > 12
    dim = days_in_month(month)
    return false if dim.nil?
    return false if day < 1 || day > dim
    true
  end

  def get_weekdays_in_month(month)
    return [] if @year.nil?
    month = month.to_i
    return [] if month < 1 || month > 12
    dim = days_in_month(month)
    return [] if dim.nil?
    weekdays = []
    (1..dim).each do |d|
      dow = day_of_week(month, d)
      next if dow.nil?
      name = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)[dow]
      weekdays << name
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if @year.nil?
    month = month.to_i
    target_day = target_day.to_i
    return 0 if month < 1 || month > 12
    dim = days_in_month(month)
    return 0 if dim.nil?
    count = 0
    (1..dim).each do |d|
      dow = day_of_week(month, d)
      count += 1 if dow == target_day
    end
    count
  end

  private

  def days_since_epoch
    y = @year
    return 0 if y.nil? || y < 1
    (y - 1) * 365 + (y - 1) / 4 - (y - 1) / 100 + (y - 1) / 400
  end
end