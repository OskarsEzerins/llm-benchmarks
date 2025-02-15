require 'benchmark'
require 'securerandom'

module DataGenerator
  def self.generate_test_data
    header = "name,age,city,occupation,salary,department,years_experience," \
             "education,performance_rating,projects_completed,team_size," \
             "remote_work_ratio,last_promotion,certifications"
    rows = Array.new(100_000) { generate_row }
    [header, *rows]
  end

  def self.generate_row
    [
      ["John", "Alice", "Bob", "Emma", "Michael", "Sarah", "David", "Lisa", "James", "Emily"].sample,
      rand(20..65),
      ["New York", "San Francisco", "Chicago", "Boston", "Seattle", "Austin", "Denver", "Miami", "Portland", "London",
       "Berlin", "Tokyo"].sample,
      ["Engineer", "Designer", "Manager", "Developer", "Analyst", "Architect", "Consultant", "Director", "VP",
       "Specialist"].sample,
      rand(50_000..300_000),
      ["Engineering", "Design", "Product", "Sales", "Marketing", "Operations", "Research", "Data Science"].sample,
      rand(1..25),
      ["Bachelor's", "Master's", "PhD", "High School", "Associate's", "Professional Degree"].sample,
      rand(1.0..5.0).round(1),
      rand(1..50),
      rand(1..20),
      rand(0.0..1.0).round(2),
      (Time.now - (rand(0..1825) * 24 * 60 * 60)).strftime("%Y-%m-%d"),
      rand(0..5)
    ].join(",")
  end
end

module Aggregations
  def self.calculate_average(data_rows, field)
    data_rows.sum { |row| row[field].to_i } / data_rows.length.to_f
  end

  def self.group_and_count(data_rows, field)
    data_rows.group_by { |row| row[field] }.transform_values(&:count)
  end

  def self.calculate_dept_salary_avg(data_rows)
    data_rows.group_by { |row| row["department"] }
             .transform_values { |dept_rows| calculate_average(dept_rows, "salary") }
  end

  def self.calculate_weighted_average(data_rows, value_field, weight_field)
    weighted_sum = data_rows.sum { |row| row[value_field].to_f * row[weight_field].to_f }
    weights_sum = data_rows.sum { |row| row[weight_field].to_f }
    weighted_sum / weights_sum
  end

  def self.calculate_percentile(data_rows, field, percentile)
    values = data_rows.map { |row| row[field].to_f }.sort
    index = (values.length * percentile).ceil - 1
    values[index]
  end

  def self.basic_aggregations
    {
      avg_age: ->(data_rows) { calculate_average(data_rows, "age") },
      avg_salary: ->(data_rows) { calculate_average(data_rows, "salary") },
      city_count: ->(data_rows) { group_and_count(data_rows, "city") },
      education_distribution: ->(data_rows) { group_and_count(data_rows, "education") }
    }
  end

  def self.salary_metrics
    {
      dept_salary_avg: ->(data_rows) { calculate_dept_salary_avg(data_rows) },
      performance_weighted_salary: lambda { |data_rows|
        calculate_weighted_average(data_rows, "salary", "performance_rating")
      },
      salary_90th_percentile: ->(data_rows) { calculate_percentile(data_rows, "salary", 0.9) }
    }
  end

  def self.calculate_dept_performance(data_rows)
    data_rows.group_by { |row| row["department"] }
             .transform_values do |dept_rows|
      calculate_weighted_average(dept_rows, "performance_rating",
                                 "years_experience")
    end
  end

  def self.calculate_remote_productivity(data_rows)
    data_rows.group_by { |row| (row["remote_work_ratio"].to_f * 10).floor / 10.0 }
             .transform_values { |group| calculate_average(group, "projects_completed") }
  end

  def self.calculate_team_efficiency(data_rows)
    data_rows.group_by { |row| row["department"] }
             .transform_values do |dept_rows|
      projects = dept_rows.sum { |row| row["projects_completed"].to_i }
      team_size = dept_rows.sum { |row| row["team_size"].to_i }
      projects.to_f / team_size
    end
  end

  def self.performance_metrics
    {
      dept_performance: ->(data_rows) { calculate_dept_performance(data_rows) },
      remote_productivity: ->(data_rows) { calculate_remote_productivity(data_rows) },
      team_efficiency: ->(data_rows) { calculate_team_efficiency(data_rows) }
    }
  end

  def self.advanced_metrics
    salary_metrics.merge(performance_metrics)
  end

  def self.setup_aggregations
    basic_aggregations.merge(advanced_metrics)
  end
end

class CsvProcessorBenchmark
  def self.run(implementation_path)
    require_relative implementation_path
    csv_file = File.join(File.dirname(__FILE__), 'test_data.csv')
    data = File.readlines(csv_file).map(&:chomp)

    transformations = setup_transformations

    time = Benchmark.realtime do
      result = CsvProcessor.process(data, transformations)
      validate_output(result)
    end

    time.round(4)
  end

  def self.meets_demographic_criteria?(row)
    row["age"].to_i > 30 &&
      row["salary"].to_i > 100_000 &&
      row["years_experience"].to_i >= 5
  end

  def self.meets_performance_criteria?(row)
    row["performance_rating"].to_f >= 4.0 &&
      row["projects_completed"].to_i >= 10 &&
      row["team_size"].to_i >= 5 &&
      row["remote_work_ratio"].to_f >= 0.5 &&
      row["certifications"].to_i >= 2
  end

  def self.filter_conditions
    lambda { |row|
      meets_demographic_criteria?(row) && meets_performance_criteria?(row)
    }
  end

  def self.setup_transformations
    {
      filter: filter_conditions,
      select: ["name", "city", "occupation", "department", "salary", "performance_rating", "remote_work_ratio"],
      aggregate: Aggregations.setup_aggregations
    }
  end

  def self.validate_output(result)
    required_keys = %i[
      avg_age avg_salary city_count dept_salary_avg education_distribution
      performance_weighted_salary salary_90th_percentile dept_performance
      remote_productivity team_efficiency
    ]

    validations = {
      filtered_data: result[:filtered_data].is_a?(Array),
      aggregations: result[:aggregations].is_a?(Hash),
      filtered_data_structure: result[:filtered_data].all?(Hash),
      required_aggregations: required_keys.all? { |key| result[:aggregations].key?(key) }
    }

    validations.each do |check, valid|
      raise "#{check.to_s.tr('_', ' ').capitalize} validation failed" unless valid
    end
  end
end
