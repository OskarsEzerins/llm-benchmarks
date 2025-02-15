require 'rubocop'
require 'stringio'
require 'json'
require 'tempfile'

class RubocopEvaluationService
  def self.count_offenses(file_path)
    temp_file = Tempfile.new(['rubocop', '.json'])
    options = {
      formatters: [['json', temp_file.path]],
      stderr: StringIO.new,
      stdout: StringIO.new
    }

    config_store = RuboCop::ConfigStore.new
    runner = RuboCop::Runner.new(options, config_store)
    runner.run([File.expand_path(file_path)])

    result = JSON.parse(File.read(temp_file.path))
    temp_file.close
    temp_file.unlink

    result['summary']['offense_count']
  end
end
