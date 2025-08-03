# frozen_string_literal: true

require 'minitest/autorun'

# Load the working app for testing during development
require_relative 'working_app'

# Original ParkingGarage tests
class ParkingGarageTest < Minitest::Test
  def setup
    @garage = ParkingGarage.new(2, 2, 2)
  end

  # Basic functionality tests
  def test_initialization
    assert_instance_of ParkingGarage, @garage
    assert_equal 2, @garage.small
    assert_equal 2, @garage.medium
    assert_equal 2, @garage.large
    assert_equal({ small_spot: [], medium_spot: [], large_spot: [] }, @garage.parking_spots)
  end

  def test_small_car_parks_in_small_spot
    result = @garage.admit_car('ABC123', 'small')
    assert_equal 'car with license plate no. ABC123 is parked at small', result
    assert_equal 1, @garage.small
    assert_equal 1, @garage.parking_spots[:small_spot].size
  end

  def test_medium_car_parks_in_medium_spot
    result = @garage.admit_car('XYZ789', 'medium')
    assert_equal 'car with license plate no. XYZ789 is parked at medium', result
    assert_equal 1, @garage.medium
    assert_equal 1, @garage.parking_spots[:medium_spot].size
  end

  def test_large_car_parks_in_large_spot
    result = @garage.admit_car('LRG999', 'large')
    assert_equal 'car with license plate no. LRG999 is parked at large', result
    assert_equal 1, @garage.large
    assert_equal 1, @garage.parking_spots[:large_spot].size
  end

  # Cascading spot allocation tests
  def test_small_car_cascades_to_medium_when_small_full
    @garage.admit_car('S1', 'small')
    @garage.admit_car('S2', 'small')
    result = @garage.admit_car('S3', 'small')
    assert_equal 'car with license plate no. S3 is parked at medium', result
    assert_equal 0, @garage.small
    assert_equal 1, @garage.medium
  end

  def test_small_car_cascades_to_large_when_small_and_medium_full
    @garage.admit_car('S1', 'small')
    @garage.admit_car('S2', 'small')
    @garage.admit_car('M1', 'medium')
    @garage.admit_car('M2', 'medium')
    result = @garage.admit_car('S3', 'small')
    assert_equal 'car with license plate no. S3 is parked at large', result
    assert_equal 0, @garage.small
    assert_equal 0, @garage.medium
    assert_equal 1, @garage.large
  end

  def test_medium_car_cascades_to_large_when_medium_full
    @garage.admit_car('M1', 'medium')
    @garage.admit_car('M2', 'medium')
    result = @garage.admit_car('M3', 'medium')
    assert_equal 'car with license plate no. M3 is parked at large', result
    assert_equal 0, @garage.medium
    assert_equal 1, @garage.large
  end

  # Exit functionality tests
  def test_car_exit_from_small_spot
    @garage.admit_car('ABC123', 'small')
    result = @garage.exit_car('ABC123')
    assert_equal 'car with license plate no. ABC123 exited', result
    assert_equal 2, @garage.small
    assert_empty @garage.parking_spots[:small_spot]
  end

  def test_car_exit_from_medium_spot
    @garage.admit_car('XYZ789', 'medium')
    result = @garage.exit_car('XYZ789')
    assert_equal 'car with license plate no. XYZ789 exited', result
    assert_equal 2, @garage.medium
    assert_empty @garage.parking_spots[:medium_spot]
  end

  def test_car_exit_from_large_spot
    @garage.admit_car('LRG999', 'large')
    result = @garage.exit_car('LRG999')
    assert_equal 'car with license plate no. LRG999 exited', result
    assert_equal 2, @garage.large
    assert_empty @garage.parking_spots[:large_spot]
  end

  # Edge case tests
  def test_no_space_available_when_garage_full
    @garage.admit_car('S1', 'small')
    @garage.admit_car('S2', 'small')
    @garage.admit_car('M1', 'medium')
    @garage.admit_car('M2', 'medium')
    @garage.admit_car('L1', 'large')
    @garage.admit_car('L2', 'large')

    result = @garage.admit_car('FULL', 'small')
    assert_equal 'No space available', result
  end

  def test_car_not_found_exit
    result = @garage.exit_car('NOTFOUND')
    assert_equal 'Car not found!', result
  end

  # Input validation tests
  def test_invalid_car_size
    result = @garage.admit_car('ABC123', 'invalid')
    assert_equal 'No space available', result
  end

  def test_nil_inputs_admit_car
    result = @garage.admit_car(nil, 'small')
    assert_equal 'No space available', result

    result = @garage.admit_car('ABC123', nil)
    assert_equal 'No space available', result
  end

  def test_empty_license_plate
    result = @garage.admit_car('', 'small')
    assert_equal 'No space available', result

    result = @garage.admit_car('   ', 'small')
    assert_equal 'No space available', result
  end

  def test_nil_license_plate_exit
    result = @garage.exit_car(nil)
    assert_equal 'Car not found!', result
  end

  def test_empty_license_plate_exit
    result = @garage.exit_car('')
    assert_equal 'Car not found!', result
  end

  # Case sensitivity tests
  def test_case_insensitive_car_sizes
    result1 = @garage.admit_car('UP1', 'SMALL')
    assert_equal 'car with license plate no. UP1 is parked at small', result1

    result2 = @garage.admit_car('UP2', 'Medium')
    assert_equal 'car with license plate no. UP2 is parked at medium', result2

    result3 = @garage.admit_car('UP3', 'Large')
    assert_equal 'car with license plate no. UP3 is parked at large', result3
  end

  # Complex shuffling tests
  def test_medium_car_shuffling_when_no_medium_spots
    # Fill medium spots with small cars by cascading
    @garage.admit_car('S1', 'small')
    @garage.admit_car('S2', 'small')
    @garage.admit_car('S3', 'small')  # This goes to medium
    @garage.admit_car('S4', 'small')  # This goes to medium

    # Now try to park a medium car - should shuffle
    result = @garage.admit_car('M1', 'medium')
    expected_results = ['car with license plate no. M1 is parked at medium',
                        'car with license plate no. M1 is parked at large']
    assert_includes expected_results, result
  end

  def test_large_car_shuffling_when_no_large_spots
    # Fill all spots but leave room for shuffling
    @garage.admit_car('S1', 'small')
    @garage.admit_car('S2', 'small')
    @garage.admit_car('S3', 'small') # This goes to medium
    @garage.admit_car('L1', 'large')
    @garage.admit_car('L2', 'large')

    # Now try to park another large car - should try to shuffle but fail
    result = @garage.admit_car('L3', 'large')
    assert_equal 'No space available', result
  end

  # Mixed type parking and exit tests
  def test_mixed_operations
    @garage.admit_car('S1', 'small')
    @garage.admit_car('M1', 'medium')
    @garage.admit_car('L1', 'large')

    @garage.exit_car('M1')
    assert_equal 2, @garage.medium

    result = @garage.admit_car('M2', 'medium')
    assert_equal 'car with license plate no. M2 is parked at medium', result
  end

  def test_string_and_numeric_license_plates
    @garage.admit_car(123, 'small')
    result = @garage.exit_car('123')
    assert_equal 'car with license plate no. 123 exited', result

    @garage.admit_car('ABC456', 'medium')
    result = @garage.exit_car('ABC456')
    assert_equal 'car with license plate no. ABC456 exited', result
  end
end

# New module tests for extended functionality
class ParkingTicketTest < Minitest::Test
  def setup
    @ticket = ParkingTicket.new('ABC123', 'small', Time.now)
  end

  def test_ticket_initialization
    assert_instance_of ParkingTicket, @ticket
    assert_equal 'ABC123', @ticket.license_plate
    assert_equal 'small', @ticket.car_size
    assert_instance_of Time, @ticket.entry_time
    refute_nil @ticket.ticket_id
  end

  def test_ticket_id_uniqueness
    ticket1 = ParkingTicket.new('ABC123', 'small', Time.now)
    ticket2 = ParkingTicket.new('XYZ789', 'medium', Time.now)
    refute_equal ticket1.ticket_id, ticket2.ticket_id
  end

  def test_duration_calculation
    entry_time = Time.now - 3600
    ticket = ParkingTicket.new('ABC123', 'small', entry_time)
    duration = ticket.duration_hours
    assert_in_delta 1.0, duration, 0.1
  end

  def test_is_valid
    assert @ticket.valid?

    expired_ticket = ParkingTicket.new('OLD123', 'small', Time.now - (25 * 3600))
    refute expired_ticket.valid?
  end
end

class ParkingFeeCalculatorTest < Minitest::Test
  def setup
    @calculator = ParkingFeeCalculator.new
  end

  def test_hourly_rates
    assert_equal 2.0, @calculator.calculate_fee('small', 1.0)
    assert_equal 3.0, @calculator.calculate_fee('medium', 1.0)
    assert_equal 5.0, @calculator.calculate_fee('large', 1.0)
  end

  def test_partial_hour_rounding
    assert_equal 2.0, @calculator.calculate_fee('small', 0.5)
    assert_equal 4.0, @calculator.calculate_fee('small', 1.1)
  end

  def test_daily_maximum
    assert_equal 20.0, @calculator.calculate_fee('small', 12.0)
    assert_equal 30.0, @calculator.calculate_fee('medium', 12.0)
    assert_equal 50.0, @calculator.calculate_fee('large', 12.0)
  end

  def test_free_grace_period
    assert_equal 0.0, @calculator.calculate_fee('small', 0.25)
  end

  def test_invalid_car_size
    assert_raises(ArgumentError) { @calculator.calculate_fee('invalid', 1.0) }
  end
end

class ParkingGarageManagerTest < Minitest::Test
  def setup
    @manager = ParkingGarageManager.new(2, 2, 2)
  end

  def test_manager_initialization
    assert_instance_of ParkingGarageManager, @manager
    assert_instance_of ParkingGarage, @manager.garage
    assert_instance_of ParkingFeeCalculator, @manager.fee_calculator
    assert_empty @manager.active_tickets
  end

  def test_admit_car_with_ticket
    result = @manager.admit_car('ABC123', 'small')

    assert result[:success]
    assert_equal 'car with license plate no. ABC123 is parked at small', result[:message]
    assert_instance_of ParkingTicket, result[:ticket]
    assert_equal 1, @manager.active_tickets.size
  end

  def test_admit_car_validation
    result = @manager.admit_car(nil, 'small')
    refute result[:success]
    assert_equal 'Invalid license plate or car size', result[:message]

    result = @manager.admit_car('ABC123', 'invalid')
    refute result[:success]
    assert_equal 'Invalid license plate or car size', result[:message]
  end

  def test_exit_car_with_fee_calculation
    admit_result = @manager.admit_car('ABC123', 'small')
    ticket = admit_result[:ticket]

    ticket.instance_variable_set(:@entry_time, Time.now - 3600)

    exit_result = @manager.exit_car('ABC123')

    assert exit_result[:success]
    assert_equal 'car with license plate no. ABC123 exited', exit_result[:message]
    assert_in_delta 2.0, exit_result[:fee], 2.0 # Account for hour rounding
    assert_in_delta 1.0, exit_result[:duration_hours], 0.1
    assert_empty @manager.active_tickets
  end

  def test_exit_car_not_found
    result = @manager.exit_car('NOTFOUND')
    refute result[:success]
    assert_equal 'Car not found!', result[:message]
    assert_equal 0.0, result[:fee]
  end

  def test_garage_status
    @manager.admit_car('S1', 'small')
    @manager.admit_car('M1', 'medium')

    status = @manager.garage_status
    assert_equal 1, status[:small_available]
    assert_equal 1, status[:medium_available]
    assert_equal 2, status[:large_available]
    assert_equal 2, status[:total_occupied]
    assert_equal 4, status[:total_available]
  end

  def test_find_ticket_by_license_plate
    @manager.admit_car('ABC123', 'small')
    ticket = @manager.find_ticket('ABC123')

    assert_instance_of ParkingTicket, ticket
    assert_equal 'ABC123', ticket.license_plate

    assert_nil @manager.find_ticket('NOTFOUND')
  end

  def test_multiple_cars_operations
    @manager.admit_car('S1', 'small')
    @manager.admit_car('S2', 'small')
    @manager.admit_car('M1', 'medium')

    assert_equal 3, @manager.active_tickets.size

    @manager.exit_car('S1')
    assert_equal 2, @manager.active_tickets.size

    status = @manager.garage_status
    assert_equal 1, status[:small_available]
    assert_equal 1, status[:medium_available]
    assert_equal 2, status[:total_occupied]
  end
end
