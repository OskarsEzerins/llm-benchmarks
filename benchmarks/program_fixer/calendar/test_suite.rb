# frozen_string_literal: true

class CalendarTest < Minitest::Test
  def setup
    @calendar = Calendar.new(2024) # 2024 is a leap year
  end

  def test_initialization_with_valid_year
    calendar = Calendar.new(2023)
    assert_equal 2023, calendar.year
  end

  def test_initialization_with_invalid_inputs
    # Should handle nil gracefully
    calendar_nil = Calendar.new(nil)
    assert_nil calendar_nil.year

    # Should handle negative years gracefully
    calendar_negative = Calendar.new(-2024)
    assert_nil calendar_negative.year

    # Should handle non-numeric inputs gracefully
    calendar_string = Calendar.new("invalid")
    assert_nil calendar_string.year
  end

  def test_leap_year_detection
    # Test leap year (2024)
    assert @calendar.is_leap_year?

    # Test non-leap year
    calendar_2023 = Calendar.new(2023)
    assert !calendar_2023.is_leap_year?

    # Test century year that is leap year
    calendar_2000 = Calendar.new(2000)
    assert calendar_2000.is_leap_year?

    # Test century year that is not leap year
    calendar_1900 = Calendar.new(1900)
    assert !calendar_1900.is_leap_year?
  end

  def test_days_in_month_regular_year
    calendar = Calendar.new(2023) # Non-leap year

    assert_equal 31, calendar.days_in_month(1)  # January
    assert_equal 28, calendar.days_in_month(2)  # February (non-leap)
    assert_equal 31, calendar.days_in_month(3)  # March
    assert_equal 30, calendar.days_in_month(4)  # April
    assert_equal 31, calendar.days_in_month(5)  # May
    assert_equal 30, calendar.days_in_month(6)  # June
    assert_equal 31, calendar.days_in_month(7)  # July
    assert_equal 31, calendar.days_in_month(8)  # August
    assert_equal 30, calendar.days_in_month(9)  # September
    assert_equal 31, calendar.days_in_month(10) # October
    assert_equal 30, calendar.days_in_month(11) # November
    assert_equal 31, calendar.days_in_month(12) # December
  end

  def test_days_in_month_leap_year
    # February in leap year
    assert_equal 29, @calendar.days_in_month(2)
  end

  def test_days_in_month_invalid_inputs
    # Invalid month numbers should return nil
    assert_nil @calendar.days_in_month(0)
    assert_nil @calendar.days_in_month(13)
    assert_nil @calendar.days_in_month(nil)
    assert_nil @calendar.days_in_month(-1)
  end

  def test_day_of_week_calculation
    # January 1, 2024 is a Monday (day 1)
    assert_equal 1, @calendar.day_of_week(1, 1)

    # December 31, 2024 is a Tuesday (day 2)
    assert_equal 2, @calendar.day_of_week(12, 31)

    # February 29, 2024 (leap day) is a Thursday (day 4)
    assert_equal 4, @calendar.day_of_week(2, 29)

    # July 4, 2024 is a Thursday (day 4)
    assert_equal 4, @calendar.day_of_week(7, 4)
  end

  def test_get_month_name
    assert_equal "January", @calendar.get_month_name(1)
    assert_equal "February", @calendar.get_month_name(2)
    assert_equal "March", @calendar.get_month_name(3)
    assert_equal "April", @calendar.get_month_name(4)
    assert_equal "May", @calendar.get_month_name(5)
    assert_equal "June", @calendar.get_month_name(6)
    assert_equal "July", @calendar.get_month_name(7)
    assert_equal "August", @calendar.get_month_name(8)
    assert_equal "September", @calendar.get_month_name(9)
    assert_equal "October", @calendar.get_month_name(10)
    assert_equal "November", @calendar.get_month_name(11)
    assert_equal "December", @calendar.get_month_name(12)
  end

  def test_get_month_name_invalid_inputs
    assert_nil @calendar.get_month_name(0)
    assert_nil @calendar.get_month_name(13)
    assert_nil @calendar.get_month_name(nil)
    assert_nil @calendar.get_month_name(-1)
  end

  def test_format_date
    assert_equal "2024-03-15", @calendar.format_date(3, 15)
    assert_equal "2024-12-01", @calendar.format_date(12, 1)
    assert_equal "2024-01-01", @calendar.format_date(1, 1)
    assert_equal "2024-02-29", @calendar.format_date(2, 29) # Leap day
  end

  def test_format_date_with_padding
    # Should pad single digits with zeros
    assert_equal "2024-01-05", @calendar.format_date(1, 5)
    assert_equal "2024-09-07", @calendar.format_date(9, 7)
  end

  def test_format_date_invalid_inputs
    # Should return nil for invalid dates
    assert_nil @calendar.format_date(0, 1)
    assert_nil @calendar.format_date(13, 1)
    assert_nil @calendar.format_date(1, 0)
    assert_nil @calendar.format_date(2, 30) # February doesn't have 30 days
  end

  def test_get_days_until_date
    # Days from Jan 1 to Jan 1 should be 0
    assert_equal 0, @calendar.get_days_until_date(1, 1)

    # Days from Jan 1 to Jan 2 should be 1
    assert_equal 1, @calendar.get_days_until_date(1, 2)

    # Days from Jan 1 to Feb 1 should be 31
    assert_equal 31, @calendar.get_days_until_date(2, 1)

    # Days from Jan 1 to March 1 should be 60 (31 + 29 for leap year)
    assert_equal 60, @calendar.get_days_until_date(3, 1)

    # Days from Jan 1 to Dec 25 should be 359
    assert_equal 359, @calendar.get_days_until_date(12, 25)

    # Days from Jan 1 to Dec 31 should be 365 (leap year)
    assert_equal 365, @calendar.get_days_until_date(12, 31)
  end

  def test_get_days_until_date_invalid_inputs
    assert_nil @calendar.get_days_until_date(0, 1)
    assert_nil @calendar.get_days_until_date(13, 1)
    assert_nil @calendar.get_days_until_date(1, 0)
    assert_nil @calendar.get_days_until_date(2, 30)
  end

  def test_is_valid_date
    # Valid dates
    assert @calendar.is_valid_date?(1, 1)
    assert @calendar.is_valid_date?(12, 31)
    assert @calendar.is_valid_date?(2, 29) # Leap year February
    assert @calendar.is_valid_date?(4, 30) # April has 30 days

    # Invalid dates
    assert !@calendar.is_valid_date?(0, 1)     # Invalid month
    assert !@calendar.is_valid_date?(13, 1)    # Invalid month
    assert !@calendar.is_valid_date?(1, 0)     # Invalid day
    assert !@calendar.is_valid_date?(1, 32)    # January doesn't have 32 days
    assert !@calendar.is_valid_date?(2, 30)    # February doesn't have 30 days
    assert !@calendar.is_valid_date?(4, 31)    # April doesn't have 31 days
    assert !@calendar.is_valid_date?(nil, nil) # Nil inputs
  end

  def test_is_valid_date_non_leap_year
    calendar = Calendar.new(2023) # Non-leap year
    assert !calendar.is_valid_date?(2, 29) # February 29 doesn't exist in non-leap year
  end

  def test_get_weekdays_in_month
    weekdays = @calendar.get_weekdays_in_month(1) # January 2024

    # January 2024 has 31 days, should return 31 day names
    assert_equal 31, weekdays.length

    # January 1, 2024 is Monday
    assert_equal "Monday", weekdays[0]

    # January 31, 2024 is Wednesday
    assert_equal "Wednesday", weekdays[30]

    # All entries should be valid weekday names
    valid_days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    weekdays.each { |day| assert valid_days.include?(day) }
  end

  def test_get_weekdays_in_month_invalid_inputs
    assert_nil @calendar.get_weekdays_in_month(0)
    assert_nil @calendar.get_weekdays_in_month(13)
    assert_nil @calendar.get_weekdays_in_month(nil)
  end

  def test_count_occurrences_of_day
    # January 2024: Count Mondays (day 1)
    # Jan 1, 8, 15, 22, 29 are Mondays
    assert_equal 5, @calendar.count_occurrences_of_day(1, 1)

    # January 2024: Count Sundays (day 0)
    # Jan 7, 14, 21, 28 are Sundays
    assert_equal 4, @calendar.count_occurrences_of_day(1, 0)

    # February 2024: Count Thursdays (day 4)
    # Feb 1, 8, 15, 22, 29 are Thursdays
    assert_equal 5, @calendar.count_occurrences_of_day(2, 4)
  end

  def test_count_occurrences_of_day_invalid_inputs
    # Invalid month
    assert_nil @calendar.count_occurrences_of_day(0, 1)
    assert_nil @calendar.count_occurrences_of_day(13, 1)

    # Invalid day of week
    assert_nil @calendar.count_occurrences_of_day(1, -1)
    assert_nil @calendar.count_occurrences_of_day(1, 7)

    # Nil inputs
    assert_nil @calendar.count_occurrences_of_day(nil, 1)
    assert_nil @calendar.count_occurrences_of_day(1, nil)
  end

  def test_edge_cases_with_invalid_calendar
    # Calendar with invalid year
    invalid_calendar = Calendar.new(nil)

    # Should handle gracefully without crashing
    assert_nil invalid_calendar.days_in_month(1)
    assert_nil invalid_calendar.is_valid_date?(1, 1)
    assert_nil invalid_calendar.format_date(1, 1)
  end

  def test_leap_year_edge_cases
    # Test year 1600 (divisible by 400)
    calendar_1600 = Calendar.new(1600)
    assert calendar_1600.is_leap_year?
    assert_equal 29, calendar_1600.days_in_month(2)

    # Test year 1700 (divisible by 100 but not 400)
    calendar_1700 = Calendar.new(1700)
    assert !calendar_1700.is_leap_year?
    assert_equal 28, calendar_1700.days_in_month(2)
  end

  def test_comprehensive_date_validation
    # Test boundary conditions for each month
    assert @calendar.is_valid_date?(1, 31)   # January 31 - valid
    assert !@calendar.is_valid_date?(1, 32)  # January 32 - invalid

    assert @calendar.is_valid_date?(2, 29)   # February 29 in leap year - valid
    assert !@calendar.is_valid_date?(2, 30)  # February 30 - invalid

    assert @calendar.is_valid_date?(4, 30)   # April 30 - valid
    assert !@calendar.is_valid_date?(4, 31)  # April 31 - invalid

    assert @calendar.is_valid_date?(12, 31)  # December 31 - valid
    assert !@calendar.is_valid_date?(12, 32) # December 32 - invalid
  end
end
