# frozen_string_literal: true

require 'benchmark'
require 'tempfile'
require 'minitest'

class VendingMachineBenchmark
  def self.run(implementation_path)
    # Load the LLM's implementation (which should be a fixed version)
    require File.expand_path(implementation_path, File.dirname(__FILE__))
    fixed_code_class = VendingMachine

    # Create temporary file with the fixed code to run tests
    test_result = run_tests_on_fixed_code(fixed_code_class)

    {
      tests_passed: test_result[:passed],
      total_tests: test_result[:total],
      success: test_result[:passed].positive? && test_result[:syntax_valid],
      syntax_valid: test_result[:syntax_valid],
      error_message: test_result[:error_message]
    }
  rescue StandardError => e
    {
      tests_passed: 0,
      total_tests: get_total_test_count,
      success: false,
      syntax_valid: false,
      error_message: e.message
    }
  end

  def self.run_tests_on_fixed_code(vending_machine_class)
    result = { passed: 0, total: 0, syntax_valid: true, error_message: nil }

    begin
      # Get test methods from VendingMachineTest in deterministic order
      test_methods = VendingMachineTest.instance_methods(true)
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
    VendingMachineTest.instance_methods(true).count { |m| m.to_s.start_with?('test_') }
  end
end

# Load the test suite
require_relative 'test_suite'
