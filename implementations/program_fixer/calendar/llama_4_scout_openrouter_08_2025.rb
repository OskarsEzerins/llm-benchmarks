# frozen_string_literal: true

class Calendar
  attr_reader :year

  def initialize(year)
    raise TypeError, "Year must be an integer" unless year.is_a?(Integer)
    raise ArgumentError, "Year must be a positive integer" if year.nil? || year <= 0

    @year = year
  end

  def is_leap_year?
    @year % 4 == 0 && (@year % 100 != 0 || @year % 400 == 0)
  end

  def days_in_month(month)
    raise ArgumentError, "Month must be an integer between 1 and 12" unless month.is_a?(Integer) && month >= 1 && month <= 12

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    if month == 2 && is_leap_year?
      return 29
    end

    days[month - 1]
  end

  def day_of_week(month, day)
    raise ArgumentError, "Month must be an integer between 1 and 12" unless month.is_a?(Integer) && month >= 1 && month <= 12
    raise ArgumentError, "Day must be an integer between 1 and #{days_in_month(month)}" unless day.is_a?(Integer) && day >= 1 && day <= days_in_month(month)

    t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
    year_c = @year
    month_c = month
    if month_c < 3
      year_c -= 1
      month_c += 10
    end

    dow = (year_c + year_c / 4 - year_c / 100 + year_c / 400 + t[month_c - 1] + day) % 7
  end

  def get_month_name(month)
    raise ArgumentError, "Month must be an integer between 1 and 12" unless month.is_a?(Integer) && month >= 1 && month <= 12

    months = ["January", "February", "March", "April", "May", "June",
              "July", "August", "September", "October", "November", "December"]
    months[month - 1]
  end

  def format_date(month, day)
    raise ArgumentError, "Month must be an integer between 1 and 12" unless month.is_a?(Integer) && month >= 1 && month <= 12
    raise ArgumentError, "Day must be an integer between 1 and #{days_in_month(month)}" unless day.is_a?(Integer) && day >= 1 && day <= days_in_month(month)

    sprintf("%04d-%02d-%02d", @year, month, day)
  end

  def get_days_until_date(month, day)
    raise ArgumentError, "Month must be an integer between 1 and 12" unless month.is_a?(Integer) && month >= 1 && month <= 12
    raise ArgumentError, "Day must be an integer between 1 and #{days_in_month(month)}" unless day.is_a?(Integer) && day >= 1 && day <= days_in_month(month)

    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false unless month.is_a?(Integer) && day.is_a?(Integer)
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)

    true
  end

  def get_weekdays_in_month(month)
    raise ArgumentError, "Month must be an integer between 1 and 12" unless month.is_a?(Integer) && month >= 1 && month <= 12

    weekdays = []
    days_count = days_in_month(month)

    (1..days_count).each do |day|
      day_name = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
      weekdays << day_name[day_of_week(month, day)]
    end

    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    raise ArgumentError, "Month must be an integer between 1 and 12" unless month.is_a?(Integer) && month >= 1 && month <= 12
    raise ArgumentError, "Target day must be an integer between 0 and 6" unless target_day.is_a?(Integer) && target_day >= 0 && target_day <= 6

    count = 0
    days_count = days_in_month(month)

    (1..days_count).each do |day|
      count += 1 if day_of_week(month, day) == target_day
    end

    count
  end
end