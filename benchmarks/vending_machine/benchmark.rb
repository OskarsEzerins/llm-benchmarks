# frozen_string_literal: true

require 'benchmark'
require 'tempfile'

# Handle minitest loading for both standalone and subprocess execution
begin
  require 'minitest'
rescue LoadError
  begin
    require 'minitest/autorun'
  rescue LoadError
    # If minitest still not available, define minimal test framework
    module Minitest
      class Test
        def initialize(name)
          @name = name
        end

        def setup; end

        module Assertions
          class Assertion < StandardError; end

          def assert(test, msg = 'Failed assertion, no message given.')
            raise Assertion, msg unless test
          end

          def assert_equal(expected, actual, msg = nil)
            return if expected == actual

            raise Assertion, msg || "Expected #{expected.inspect}, got #{actual.inspect}"
          end

          def assert_in_delta(expected, actual, delta = 0.001, msg = nil)
            return if (expected - actual).abs <= delta

            raise Assertion, msg || "Expected #{expected} to be within #{delta} of #{actual}"
          end

          def assert_raises(exception_class)
            yield
            raise Assertion, "Expected #{exception_class} to be raised"
          rescue exception_class
            # Expected exception was raised
          end
        end

        include Assertions
      end
    end
  end
end

class VendingMachineBenchmark
  def self.run(implementation_path)
    benchmark_start_time = Time.now

    # Load the LLM's implementation (which should be a fixed version)
    require File.expand_path(implementation_path, File.dirname(__FILE__))
    fixed_code_class = VendingMachine

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

  def self.run_tests_on_fixed_code(vending_machine_class)
    result = { passed: 0, total: 0, syntax_valid: true, error_message: nil }

    begin
      # Get test methods from VendingMachineTest in deterministic order
      test_methods = VendingMachineTest.instance_methods(false)
                                       .select { |m| m.to_s.start_with?('test_') }
                                       .sort # Ensure deterministic order!
      result[:total] = test_methods.count

      test_methods.each do |test_method|
        # Create a fresh test instance for each test
        test_instance = VendingMachineTest.new(test_method.to_s)

        # Override the setup method to use our vending_machine class
        test_instance.define_singleton_method(:setup) do
          items = [
            { name: 'Cola', price: 1.50, quantity: 5 },
            { name: 'Chips', price: 1.00, quantity: 10 },
            { name: 'Candy', price: 0.75, quantity: 0 }
          ]
          @vending_machine = vending_machine_class.new(items)
        end

        # Run setup and the test method
        test_instance.setup
        test_instance.send(test_method)
        result[:passed] += 1
      rescue Minitest::Assertion, StandardError
        # Test failed, don't increment passed count
        # puts "Test #{test_method} failed: #{e.message}" # Debug output
      end
    rescue StandardError => e
      result[:syntax_valid] = false
      result[:error_message] = e.message
    end

    result
  end

  def self.get_total_test_count
    VendingMachineTest.instance_methods(false).count { |m| m.to_s.start_with?('test_') }
  end
end

# Load the test suite
require_relative 'test_suite'
