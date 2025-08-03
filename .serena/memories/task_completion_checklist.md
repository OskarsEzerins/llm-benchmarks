# Task Completion Checklist

When completing any task in this project, follow these steps:

## Code Quality Checks
1. **Run RuboCop linting**:
   ```bash
   bundle exec rubocop
   ```

2. **Run RuboCop with performance checks**:
   ```bash
   bundle exec rubocop --require rubocop-performance
   ```

## Testing
- **For Ruby code**: Use minitest framework (check existing test patterns)
- **For benchmarks**: Test implementations are automatically validated during benchmark runs
- **For website**: Use `pnpm tsc` for TypeScript checking

## Before Committing
1. Ensure RuboCop passes without violations
2. Test affected functionality manually using `bin/main`
3. For website changes, verify `pnpm tsc` passes
4. Check that any new implementations work with benchmark system

## Integration Testing
- Run relevant benchmarks to ensure changes don't break existing functionality
- For new benchmark types, test the full pipeline from prompt to results

## Documentation
- Update CLAUDE.md if architectural changes are made
- No forced documentation due to Style/Documentation being disabled
- Focus on clear, self-documenting code following established patterns

## Performance Considerations
- Be mindful of benchmark timing accuracy
- Ensure new code doesn't introduce performance regressions
- Test with realistic data sizes for performance benchmarks