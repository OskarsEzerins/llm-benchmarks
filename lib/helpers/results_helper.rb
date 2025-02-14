module ResultsHelper
  def calculate_best_results_by_implementation(results)
    results.group_by { |r| r["implementation"] }
           .map { |_, impl_results| impl_results.min_by { |r| r["metrics"]["execution_time"] } }
           .sort_by { |r| r["metrics"]["execution_time"] }
  end
end
