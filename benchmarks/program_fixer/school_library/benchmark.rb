# frozen_string_literal: true

require 'benchmark'
require 'tempfile'
require 'minitest'

class SchoolLibraryBenchmark
  def self.run(implementation_path)
    benchmark_start_time = Time.now

    # Load the LLM's implementation (which should be a fixed version)
    require File.expand_path(implementation_path, File.dirname(__FILE__))

    # Create temporary file with the fixed code to run tests
    test_result = run_tests_on_fixed_code

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
      total_tests: total_test_count,
      success: false,
      execution_time: 0,
      syntax_valid: false,
      error_message: e.message
    }
  end

  def self.run_tests_on_fixed_code
    result = { passed: 0, total: 0, syntax_valid: true, error_message: nil }

    begin
      # Get test methods from SchoolLibraryTest in deterministic order
      test_methods = SchoolLibraryTest.instance_methods(true)
                                      .select { |m| m.to_s.start_with?('test_') }
                                      .sort # Ensure deterministic order!
      result[:total] = test_methods.count

      test_methods.each do |test_method|
        # Create a fresh test instance for each test
        test_instance = SchoolLibraryTest.new(test_method.to_s)

        # Override the setup method to use our classes
        test_instance.define_singleton_method(:setup) do
          @app = App.new
          @old_stdout = $stdout
          @old_stdin = $stdin
        end

        # Override teardown method
        test_instance.define_singleton_method(:teardown) do
          $stdout = @old_stdout
          $stdin = @old_stdin
        end

        # Run setup and the test method
        test_instance.setup
        test_instance.send(test_method)
        test_instance.teardown
        result[:passed] += 1
      rescue Minitest::Assertion, StandardError
        # Test failed, don't increment passed count
        test_instance.teardown if test_instance.respond_to?(:teardown)
      end
    rescue StandardError => e
      result[:syntax_valid] = false
      result[:error_message] = e.message
    end

    result
  end

  def self.total_test_count
    SchoolLibraryTest.instance_methods(true).count { |m| m.to_s.start_with?('test_') }
  end
end

# Load the test suite
require_relative 'test_suite'
