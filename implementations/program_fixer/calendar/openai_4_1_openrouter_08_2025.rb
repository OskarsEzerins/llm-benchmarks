class Calendar
  attr_reader :year

  MONTH_NAMES = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ]

  DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  WEEKDAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

  def initialize(year)
    if year.is_a?(Integer) && year > 0
      @year = year
    else
      @year = 1970
    end
  end

  def is_leap_year?
    (@year % 4 == 0) && ((@year % 100 != 0) || (@year % 400 == 0))
  end

  def days_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    if month == 2 && is_leap_year?
      29
    else
      DAYS_IN_MONTH[month - 1]
    end
  end

  def day_of_week(month, day)
    return nil unless is_valid_date?(month, day)
    # Zeller's Congruence (0=Saturday, 1=Sunday, ..., 6=Friday)
    m = month
    y = @year
    if m < 3
      m += 12
      y -= 1
    end
    k = y % 100
    j = y / 100
    h = (day + (13 * (m + 1)) / 5 + k + k/4 + j/4 + 5*j) % 7
    # Zeller's: 0=Saturday, 1=Sunday,...,6=Friday. Need 0=Sunday, ..., 6=Saturday
    zeller_to_weekday = {0 => 6, 1 => 0, 2 => 1, 3 => 2, 4 => 3, 5 => 4, 6 => 5}
    zeller_to_weekday[h]
  end

  def get_month_name(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    MONTH_NAMES[month - 1]
  end

  def format_date(month, day)
    return nil unless is_valid_date?(month, day)
    "%04d-%02d-%02d" % [@year, month, day]
  end

  def get_days_until_date(month, day)
    return nil unless is_valid_date?(month, day)
    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false unless month >= 1 && month <= 12
    dim = days_in_month(month)
    return false unless dim && day >= 1 && day <= dim
    true
  end

  def get_weekdays_in_month(month)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    res = []
    (1..days_in_month(month)).each do |d|
      wd = day_of_week(month, d)
      res << WEEKDAY_NAMES[wd] if wd
    end
    res
  end

  def count_occurrences_of_day(month, target_day)
    return nil unless month.is_a?(Integer) && month >= 1 && month <= 12
    return nil unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6
    count = 0
    (1..days_in_month(month)).each do |d|
      count += 1 if day_of_week(month, d) == target_day
    end
    count
  end
end