# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is an LLM benchmarking system written in Ruby that tests AI models across multiple coding challenges. The system automatically generates implementations from different AI models and compares their performance.

### Core Components

- **Benchmarks** (`benchmarks/`): Organized by benchmark type, e.g. `performance/lru_cache`, `program_fixer/vending_machine`
- **Implementations** (`implementations/`): Organized by benchmark type and benchmark id, e.g. `performance/lru_cache`, `program_fixer/vending_machine`
- **Services** (`lib/services/`): Core logic for running benchmarks, evaluating code quality, and displaying results
- **Results** (`results/`): One JSON file per implementation (e.g. `results/claude_sonnet_4_6_openrouter_02_2026.json`), containing that implementation's results across all benchmarks

### Key Services

- `BenchmarkRunnerService`: Orchestrates benchmark execution with multiple iterations in separate processes
- `ImplementationSelectorService`: Handles selection of implementations to test
- `RubocopEvaluationService`: Evaluates code quality using RuboCop
- `ResultsService`/`ResultsDisplayService`: Manages result storage and display
- `Implementations::Adder`: Generates new implementations using OpenRouter API models

### Results Storage

Results are stored **per-implementation** rather than per-benchmark. Each model gets its own `results/{implementation}.json` file containing results for every benchmark it has run. This design eliminates merge conflicts — adding a new model only creates new files.

`bin/aggregate_results` aggregates these per-implementation files into per-benchmark JSON files consumed by the website. It runs automatically via `prebuild`/`predev` npm scripts before building or serving the website. The aggregated output goes to `website/public/data/` (gitignored).

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

# Install dependencies
bundle install
```

### Results and Rankings

```bash
# Show results for all benchmarks
bin/show_all_results

# Show total rankings across all benchmark types
bin/show_total_rankings

# Aggregate per-implementation results into per-benchmark JSON for the website
bin/aggregate_results website/public/data
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

## Adding a New Model

To add a new model's implementations via PR:

1. Run `bin/main` and choose to generate implementations for the desired model
2. This creates implementation files under `implementations/` and a results file at `results/{implementation}.json`
3. Open a PR — since each model has its own result file, there are no merge conflicts with concurrent PRs

## Website

The `website/` directory contains a React/TypeScript frontend. See `website/CLAUDE.md` for detailed instructions. All website features must be mobile-responsive (375px+ viewports).
