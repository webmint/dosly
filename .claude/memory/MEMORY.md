# Project Memory — dosly

## Project Structure
Greenfield Flutter mobile app (iOS + Android) following Clean Architecture. Source not yet scaffolded — run `flutter create .` to bootstrap, then create `lib/core/` and `lib/features/[feature]/{data,domain,presentation}/` per the layout in `CLAUDE.md`.

## Key File Paths
- `lib/main.dart` — app entry point (will be created by `flutter create .`)
- `lib/core/` — shared utilities: errors, theme, routing, constants
- `lib/core/error/failures.dart` — `Failure` base class + concrete failures (`NetworkFailure`, `ServerFailure`, `CacheFailure`, `ValidationFailure`, `AuthFailure`, `NotFoundFailure`)
- `lib/features/[feature]/domain/` — pure Dart: entities, abstract repository contracts, use cases. **No Flutter imports allowed here.**
- `lib/features/[feature]/data/` — repository implementations, data sources (REST + local), DTOs
- `lib/features/[feature]/presentation/` — Riverpod providers, screens, widgets
- `test/` — mirrors `lib/`
- `pubspec.yaml` — dependencies (will be created by `flutter create .`)
- `analysis_options.yaml` — `dart analyze` rules (use `flutter_lints` as the base)

## Workspace Configuration
- **Mode**: standalone
- **Source Root**: .

## Architecture Decisions
<!-- Populated during /constitute — records WHY decisions were made, not just what -->

- **Clean Architecture (data/domain/presentation)** — chosen during `/setup-wizard`. Rationale: enforces dependency direction, makes domain logic unit-testable without Flutter, and isolates third-party SDK choices in `data/`.
- **Either/Result types via fpdart** — chosen during `/setup-wizard`. Rationale: explicit error flow at repository boundaries; pairs naturally with Riverpod's `AsyncValue` in the UI; eliminates the "did I forget try/catch?" class of bugs.
- **Riverpod for state management** — chosen during `/setup-wizard`. Rationale: less boilerplate than BLoC for solo work, built-in DI removes need for `get_it`, `AsyncValue<T>` composes cleanly with `Either<Failure, T>`.
- **flutter_test + mocktail for testing** — chosen during `/setup-wizard`. Rationale: no codegen step (unlike mockito), null-safe out of the box, official Flutter test runner.

## Naming Conventions
<!-- Extracted during /constitute -->

- **Filenames**: `snake_case.dart` (Dart standard)
- **Types/classes/widgets**: `UpperCamelCase`
- **Variables/functions/methods**: `lowerCamelCase`
- **Constants**: `lowerCamelCase` with `const` (NOT `SCREAMING_SNAKE_CASE` — this is Dart, not Java)
- **Use cases**: verb phrase (`SignIn`, `GetUserById`, `CreateNote`)
- **Failures**: noun + `Failure` suffix (`NetworkFailure`, `ValidationFailure`)
- **Riverpod providers**: `xxxProvider` suffix (e.g., `userRepositoryProvider`, `authStateProvider`)

## Known Pitfalls
<!-- Populated during work as mistakes are discovered -->

- **`package:flutter/*` in `domain/`** — strictly forbidden. The domain layer must run in plain Dart tests without `flutter_test`.
- **`!` null assertion** — every use is a latent runtime crash. Replace with explicit null checks or restructure to make the value provably non-null.
- **`SharedPreferences` for sensitive data** — never. Use `flutter_secure_storage` for tokens, credentials, PII.
- **`ref.read` inside provider `build`** — breaks reactivity. Use `ref.watch` to express dependencies.

## What Worked
<!-- Patterns and approaches that solved problems well -->

## What Failed
<!-- Approaches that were tried and didn't work — avoid repeating these -->

## External API Quirks
<!-- Unexpected behavior from APIs, libraries, or services this project uses -->

## Performance Notes
<!-- Any performance-sensitive areas or optimizations that matter -->

- **Profile in profile mode**, never debug. Debug mode disables many optimizations and gives misleading numbers.
- **`const` constructors are free wins** — every widget that takes only compile-time constants should be `const`.
- **`ListView.builder` over `ListView(children: [...])`** for any list that might exceed ~10 items.
