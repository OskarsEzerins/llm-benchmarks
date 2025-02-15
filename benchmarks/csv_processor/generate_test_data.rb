require_relative 'benchmark'
require 'csv'

output_file = File.join(File.dirname(__FILE__), 'test_data.csv')
data = DataGenerator.generate_test_data

File.write(output_file, data.join("\n"))
puts "Generated test data saved to #{output_file}"
