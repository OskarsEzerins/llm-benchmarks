class Calendar
  def initialize(year)
    @year = year
  end

  def leap_year?(year)
    (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
  end

  def days_in_month(month)
    case month
    when 1, 3, 5, 7, 8, 10, 12 then 31
    when 4, 6, 9, 11 then 30
    when 2 then 28 + (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0))
    end
  end

  def day_of_week(date)
    w = date.wday
    return w == 0 ? 7 : w
  end

  def format_date(year, month, day)
    "#{year}-#{month}-#{day}"
  end

  def get_month_name(month)
    [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ][month - 1]
  end
end

class Date
  attr_reader :year, :month, :day

  def initialize(year, month, day)
    @year = year
    @month = month
    @day = day
  end

  def format
    "#{year}-#{month}-#{day}"
  end
end

class Calendar
  include DateHelper

  def initialize(year)
    @year = year
  end

  def is_leap_year(year)
    year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
  end

  def get_days_in_month(month, year = @year)
    if month == 2
      if is_leap_year(year)
        29
      else
        28
      end
    else
      [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
    end
  end

  def get_day_of_week(date)
    (date.wday - 1) % 7
  end

  def get_week_number(date)
    (date.day - 1) / 7 + 1
  end

  def get_month_name(month)
    Date::MONTHS[month - 1]
  end
end

module Date
  class << self
    alias :today :now
  end
end