# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is an LLM benchmarking system written in Ruby that tests AI models across multiple coding challenges. The system automatically generates implementations from different AI models and compares their performance.

### Core Components

- **Benchmarks** (`benchmarks/`): Organized by benchmark type, e.g. `performance/lru_cache`, `program_fixer/vending_machine`
- **Implementations** (`implementations/`): Organized by benchmark type and benchmark id, e.g. `performance/lru_cache`, `program_fixer/vending_machine`
- **Services** (`lib/services/`): Core logic for running benchmarks, evaluating code quality, and displaying results
- **Results** (`results/`): JSON files storing performance metrics and rankings

### Key Services

- `BenchmarkRunnerService`: Orchestrates benchmark execution with multiple iterations in separate processes
- `ImplementationSelectorService`: Handles selection of implementations to test
- `RubocopEvaluationService`: Evaluates code quality using RuboCop
- `ResultsService`/`ResultsDisplayService`: Manages result storage and display
- `Implementations::Adder`: Generates new implementations using OpenRouter API models

### Benchmark Structure 

Each benchmark consists of:
- `benchmark.rb`: Contains the test logic and validation
- `prompt`: The prompt given to AI models
- Test data files (e.g., `test_data.csv`)

## Development Commands

### Main Operations
```bash
# Interactive main menu for running benchmarks or adding implementations
bin/main

# Run all benchmarks with all models
bundle exec ruby main.rb

# Install dependencies
bundle install
```

### Results and Rankings
```bash
# Show results for all benchmarks
bin/show_all_results

# Show total rankings across all benchmarks
bin/show_total_rankings
```

### Code Quality
```bash
# Run RuboCop linting (used automatically during benchmarks)
bundle exec rubocop

# Run RuboCop with performance checks
bundle exec rubocop --require rubocop-performance
```

## Environment Setup

- Requires Ruby 3.4+
- Create `.env` file with `OPENROUTER_API_KEY` for generating new implementations
- Dependencies managed via Bundler with specific RuboCop versions for consistency

## Implementation Generation

New implementations are generated via the `ruby_llm` gem using OpenRouter API. Each implementation is:
- Saved with model name and timestamp
- Automatically tested for functionality
- Evaluated for code quality using RuboCop
- Categorized as working, broken, or slow based on performance

## Performance Measurement

- Each implementation runs 5 iterations in separate processes
- Best (fastest) result is recorded
- Results include execution time and RuboCop offense count
- Broken implementations are moved to `broken/` subdirectories
- Slow implementations are moved to `slow/` subdirectories