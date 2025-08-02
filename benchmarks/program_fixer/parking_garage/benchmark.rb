# frozen_string_literal: true

require 'benchmark'
require 'tempfile'
require 'minitest'

class ParkingGarageBenchmark
  def self.run(implementation_path)
    benchmark_start_time = Time.now

    # Load the LLM's implementation (which should be a fixed version)
    require File.expand_path(implementation_path, File.dirname(__FILE__))
    fixed_code_class = ParkingGarage

    # Create temporary file with the fixed code to run tests
    test_result = run_tests_on_fixed_code(fixed_code_class)

    execution_time = Time.now - benchmark_start_time

    {
      tests_passed: test_result[:passed],
      total_tests: test_result[:total],
      success: test_result[:passed].positive? && test_result[:syntax_valid],
      execution_time: execution_time.round(4),
      syntax_valid: test_result[:syntax_valid],
      error_message: test_result[:error_message]
    }
  rescue StandardError => e
    {
      tests_passed: 0,
      total_tests: get_total_test_count,
      success: false,
      execution_time: 0,
      syntax_valid: false,
      error_message: e.message
    }
  end

  def self.run_tests_on_fixed_code(parking_garage_class)
    result = { passed: 0, total: 0, syntax_valid: true, error_message: nil }

    begin
      # Get all test classes and their test methods
      test_classes = [ParkingGarageTest, ParkingTicketTest, ParkingFeeCalculatorTest, ParkingGarageManagerTest]
      all_test_methods = []

      test_classes.each do |test_class|
        test_methods = test_class.instance_methods(true)
                                 .select { |m| m.to_s.start_with?('test_') }
                                 .sort # Ensure deterministic order!
        test_methods.each { |method| all_test_methods << [test_class, method] }
      end

      result[:total] = all_test_methods.count

      all_test_methods.each do |test_class, test_method|
        # Create a fresh test instance for each test
        test_instance = test_class.new(test_method.to_s)

        # Override the setup method based on test class
        case test_class.name
        when 'ParkingGarageTest'
          test_instance.define_singleton_method(:setup) do
            @garage = parking_garage_class.new(2, 2, 2)
          end
        when 'ParkingTicketTest'
          test_instance.define_singleton_method(:setup) do
            @ticket = ParkingTicket.new('ABC123', 'small', Time.now)
          end
        when 'ParkingFeeCalculatorTest'
          test_instance.define_singleton_method(:setup) do
            @calculator = ParkingFeeCalculator.new
          end
        when 'ParkingGarageManagerTest'
          test_instance.define_singleton_method(:setup) do
            @manager = ParkingGarageManager.new(2, 2, 2)
          end
        end

        # Run setup and the test method
        test_instance.setup
        test_instance.send(test_method)
        result[:passed] += 1
      rescue Minitest::Assertion, StandardError
        # Test failed, don't increment passed count
      end
    rescue StandardError => e
      result[:syntax_valid] = false
      result[:error_message] = e.message
    end

    result
  end

  def self.get_total_test_count
    test_classes = [ParkingGarageTest, ParkingTicketTest, ParkingFeeCalculatorTest, ParkingGarageManagerTest]
    test_classes.sum do |test_class|
      test_class.instance_methods(true).count { |m| m.to_s.start_with?('test_') }
    end
  end
end

# Load the test suite
require_relative 'test_suite'
