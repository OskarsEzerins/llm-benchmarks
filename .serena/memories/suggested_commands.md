# Suggested Commands

## Main Operations

### Interactive Menu
```bash
bin/main
```
Primary entry point with interactive menu for:
- Running benchmarks with existing implementations
- Generating new AI implementations with OpenRouter models

### Direct Benchmark Execution
```bash
bundle exec ruby main.rb
```
Alternative way to run the main application

### Results and Rankings
```bash
bin/show_all_results          # Show results for all benchmarks by category
bin/show_total_rankings       # Show combined rankings across all benchmark types
```

## Development Commands

### Dependency Management
```bash
bundle install                # Install Ruby dependencies
```

### Code Quality
```bash
bundle exec rubocop           # Run linting (used automatically during benchmarks)
bundle exec rubocop --require rubocop-performance  # Run with performance checks
```

### Website Development
```bash
cd website
pnpm install                  # Install frontend dependencies
pnpm dev                      # Start development server with data sync
pnpm build                    # Build for production
pnpm tsc                      # TypeScript type checking
```

## Debugging
```bash
pry                          # Interactive Ruby console (available in codebase)
```

## Environment Setup
- Create `.env` file with `OPENROUTER_API_KEY` for generating new implementations
- Ruby 3.4+ required