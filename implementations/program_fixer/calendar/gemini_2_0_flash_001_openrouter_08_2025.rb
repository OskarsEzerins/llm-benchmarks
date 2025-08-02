# frozen_string_literal: true

class Calendar
  attr_reader :year

  def initialize(year)
    @year = year.to_i rescue nil
    @year = nil if @year.nil? || @year <= 0
  end

  def is_leap_year?
    return false if @year.nil?
    (@year % 4 == 0 && @year % 100 != 0) || (@year % 400 == 0)
  end

  def days_in_month(month)
    return nil if month.nil? || month < 1 || month > 12 || @year.nil?

    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    if month == 2 && is_leap_year?
      return 29
    end

    days[month - 1]
  end

  def day_of_week(month, day)
    return nil if month.nil? || day.nil? || @year.nil?
    
    year = @year
    month = month.to_i
    day = day.to_i

    m = (month + 9) % 12
    y = year - (m / 10)
    c = y / 100
    ya = y % 100

    w = (day + ((13 * m - 1) / 5) + ya + (ya / 4) + (c / 4) - (2 * c)) % 7
    w = (w + 7) % 7 
    return w
  end

  def get_month_name(month)
    return nil if month.nil? || month < 1 || month > 12
    months = ["January", "February", "March", "April", "May", "June",
              "July", "August", "September", "October", "November", "December"]
    months[month - 1]
  end

  def format_date(month, day)
    return nil if @year.nil? || month.nil? || day.nil?
    month_str = month.to_s.rjust(2, '0')
    day_str = day.to_s.rjust(2, '0')
    "#{@year}-#{month_str}-#{day_str}"
  end

  def get_days_until_date(month, day)
    return nil if @year.nil? || month.nil? || day.nil?
    
    total = 0
    (1...month).each do |m|
      total += days_in_month(m)
    end
    total + day - 1
  end

  def is_valid_date?(month, day)
    return false if @year.nil? || month.nil? || day.nil?
    return false if month < 1 || month > 12
    return false if day < 1 || day > days_in_month(month)
    true
  end

  def get_weekdays_in_month(month)
    return nil if month.nil?
    
    weekdays = []
    days_count = days_in_month(month)
    
    return nil if days_count.nil?

    (1..days_count).each do |day|
      day_name = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
      weekdays << day_name[day_of_week(month, day)]
    end
    weekdays
  end

  def count_occurrences_of_day(month, target_day)
    return nil if month.nil? || target_day.nil?
    
    count = 0
    days_count = days_in_month(month)

    return nil if days_count.nil?
    
    (1..days_count).each do |day|
      count += 1 if day_of_week(month, day) == target_day
    end
    
    count
  end
end