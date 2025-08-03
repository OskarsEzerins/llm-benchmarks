# Codebase Structure

## Top-Level Organization
```
📦 llm-benchmarks/
├── 📂 benchmarks/      # Benchmark definitions and test logic
├── 📂 implementations/ # AI-generated solutions organized by type
├── 📂 lib/            # Core services and utilities
├── 📂 results/        # JSON performance data and rankings
├── 📂 website/        # React-based results dashboard
├── 📂 bin/            # Executable scripts
└── 📂 config/         # Configuration files
```

## Key Directories

### `/benchmarks/`
Organized by benchmark type:
- `performance/` - Speed/memory challenges (csv_processor, lru_cache, etc.)
- `program_fixer/` - Debugging challenges (calendar, parking_garage, etc.)
- `template/` - Template for new benchmarks

Each benchmark contains:
- `benchmark.rb` - Test logic and validation
- `prompt` - The prompt given to AI models
- Additional test data files as needed

### `/implementations/`
Mirrors benchmark structure with AI-generated solutions:
- Organized by benchmark type and specific benchmark
- Contains working, broken, and slow subdirectories
- Each implementation timestamped with model name

### `/lib/services/`
Core application services:
- `BenchmarkRunnerService` - Orchestrates benchmark execution
- `ImplementationSelectorService` - Handles implementation selection
- `RubocopEvaluationService` - Code quality evaluation
- `ResultsService`/`ResultsDisplayService` - Result management
- `Implementations::Adder` - Generates new implementations

### `/website/`
React-based frontend:
- `app/` - React Router application
- `public/` - Static assets
- Built with TypeScript, Tailwind CSS, and modern React patterns

### `/bin/`
Executable entry points:
- `main` - Primary interactive interface
- `show_all_results` - Display categorized results
- `show_total_rankings` - Combined rankings view

## Configuration Files
- `.rubocop.yml` - Ruby style configuration
- `Gemfile` - Ruby dependencies
- `package.json` - Website dependencies
- `config.rb` - Application configuration