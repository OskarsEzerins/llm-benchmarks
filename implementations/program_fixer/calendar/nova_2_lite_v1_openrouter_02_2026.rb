class Calendar
  def initialize(year)
    @year = normalize_year(year)
  end

  def year
    @year
  end

  def is_leap_year?
    @year % 4 == 0 && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    return 0 if invalid_month?(month)

    days_in_common_year = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days_in_leap_year = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    is_leap_year? ? days_in_leap_year[month - 1] : days_in_common_year[month - 1]
  end

  def day_of_week(month, day)
    return nil if invalid_month?(month) || invalid_day?(month, day)

    # January 1, 2024 was Tuesday (2)
    base_day = 2
    
    # Calculate days from Jan 1 to target date
    days_from_jan1 = (1...month).sum { |m| days_in_month(m) } + (day - 1)
    
    (base_day + days_from_jan1) % 7
  end

  def get_month_name(month)
    return nil if invalid_month?(month)

    %w[January February March April May June July August September October November December][month - 1]
  end

  def format_date(month, day)
    return nil if invalid_month?(month) || invalid_day?(month, day)

    "#{@year}-#{"%02d" % month}-#{"%02d" % day}"
  end

  def get_days_until_date(month, day)
    return nil if invalid_month?(month) || invalid_day?(month, day)

    if month == 1 && day == 1
      return 0
    end
    
    days_from_jan1 = (1...month).sum { |m| days_in_month(m) } + (day - 1)
    days_from_jan1
  end

  def is_valid_date?(month, day)
    !invalid_month?(month) && !invalid_day?(month, day)
  end

  def get_weekdays_in_month(month)
    return [] if invalid_month?(month)

    days_in_month(month).times.map { |d| 
      day = d + 1
      %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday][day_of_week(month, day)]
    }
  end

  def count_occurrences_of_day(month, target_day)
    return 0 if invalid_month?(month) || target_day < 0 || target_day > 6

    count = 0
    days_in_month(month).times do |d|
      day = d + 1
      count += 1 if day_of_week(month, day) == target_day
    end
    count
  end

  private

  def normalize_year(year)
    return nil if year.nil? || !year.is_a?(Integer) || year <= 0

    year
  end

  def invalid_month?(month)
    !month.is_a?(Integer) || month < 1 || month > 12
  end

  def invalid_day?(month, day)
    !day.is_a?(Integer) || day < 1 || day > days_in_month(month)
  end
end