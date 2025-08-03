# Code Style & Conventions

## Ruby Conventions

### RuboCop Configuration
- Target Ruby version: 3.4
- Key disabled rules for project flexibility:
  - `Style/FrozenStringLiteralComment` - Not required
  - `Style/StringLiterals` - Mixed quote styles allowed
  - `Style/Documentation` - No forced documentation
  - `Style/WordArray` - Flexible array syntax

### Metrics Limits
- `Metrics/AbcSize`: Max 20 (excluded for benchmarks)
- `Metrics/CyclomaticComplexity`: Max 10
- `Metrics/ClassLength`: Max 200 lines
- `Metrics/MethodLength`: Max 30 lines (excluded for benchmarks)

### File Organization
- Services in `lib/services/` with descriptive names
- Modules included for shared functionality (e.g., `FormatNameService`)
- Clear separation between benchmark logic and infrastructure

### Naming Patterns
- Snake_case for files and methods
- PascalCase for classes and modules
- Descriptive service class names ending in `Service`
- Clear constant definitions (e.g., `HIGH_LEVEL_OPTIONS`)

## TypeScript/React Conventions (Website)
- TypeScript strict mode enabled
- Functional components with hooks
- React Router for routing
- Tailwind CSS for styling
- Component composition with Radix UI primitives

## Excluded Areas
RuboCop excludes certain directories to maintain flexibility:
- `bin/**/*` - Executable scripts
- `implementations/**/*` - AI-generated code
- `results/**/*` - Data files
- `vendor/**/*` - Third-party code