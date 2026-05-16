class Calendar
  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = 0
    end
  end

  def is_leap_year?
    (@year % 4 == 0) && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12

    base = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 && is_leap_year?
      29
    else
      base[month - 1]
    end
  end

  def day_of_week(month, day)
    return 0 unless month.is_a?(Integer) && day.is_a?(Integer)

    m = month
    y = @year
    if month < 3
      m += 12
      y -= 1
    end
    k = y % 100
    j = y / 100
    h = (day + (13 * (m + 1) / 5) + k + k / 4 + j / 4 + 5 * j) % 7
    # h: 0=Saturday,1=Sunday,2=Monday,3=Tuesday,4=Wednesday,5=Thursday,6=Friday
    # Convert to 0=Sunday,1=Monday,...,6=Saturday
    (h + 1) % 7
  end

  def get_month_name(month)
    return "" unless month.is_a?(Integer) && month >= 1 && month <= 12

    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    "#{@year}-%02d-%02d" % [month, day]
  end

  def get_days_until_date(month, day)
    total = 0
    (1...month).each { |m| total += days_in_month(m) }
    total + day
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return [] unless month.is_a?(Integer) && month >= 1 && month <= 12

    weekdays = []
    (1..days_in_month(month)).each do |d|
      weekdays << %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, d)]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return 0 unless month.is_a?(Integer) && month >= 1 && month <= 12
    return 0 unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6

    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end