module FormatNameService
  def format_name(benchmark_id)
    benchmark_id.split('_').map(&:capitalize).join(' ')
  end
end
