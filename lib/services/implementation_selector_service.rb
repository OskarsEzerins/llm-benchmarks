require 'tty-prompt'

class ImplementationSelectorService
  RUN_ALL_OPTION = { name: 'Run all implementations', value: :all }.freeze

  def initialize(implementations_dir)
    @implementations_dir = implementations_dir
    @prompt = TTY::Prompt.new
  end

  def select(cli_implementation = nil)
    return find_implementation(cli_implementation) if cli_implementation

    implementations = available_implementations
    ensure_implementations_exist!(implementations)

    selection = prompt_for_implementation(implementations)
    return list_all if selection == :all

    find_implementation(selection)
  end

  def list_all
    implementations = available_implementations
    ensure_implementations_exist!(implementations)

    implementations.map do |name|
      { name: name, file: implementation_path(name) }
    end
  end

  private

  def available_implementations
    Dir.glob("#{@implementations_dir}/*.rb").map { |file| File.basename(file, '.rb') }
  end

  def implementation_path(name)
    "#{@implementations_dir}/#{name}.rb"
  end

  def find_implementation(name)
    file_path = implementation_path(name)
    ensure_implementation_exists!(file_path)

    { name: name, file: file_path }
  end

  def ensure_implementations_exist!(implementations)
    return unless implementations.empty?

    puts "Error: No implementations found in #{@implementations_dir}"
    exit 1
  end

  def ensure_implementation_exists!(file_path)
    return if File.exist?(file_path)

    puts "Error: Implementation file not found: #{file_path}"
    exit 1
  end

  def prompt_for_implementation(implementations)
    choices = [RUN_ALL_OPTION] + implementations.map { |impl| { name: impl, value: impl } }

    @prompt.select(
      'Choose an implementation:',
      choices,
      per_page: 20,
      filter: true,
      show_help: :always,
      cycle: true,
      filter_hint: '(Start typing to filter)'
    )
  end
end
