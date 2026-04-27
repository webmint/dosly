### Task 001: Add dependencies and core infrastructure

**Agent**: architect
**Files**:
- `pubspec.yaml` (modify via `flutter pub add`)
- `lib/core/error/failures.dart` (create)
- `lib/core/providers/shared_preferences_provider.dart` (create)

**Depends on**: None
**Blocks**: 002, 003, 004, 005, 006, 007
**Review checkpoint**: No
**Context docs**: None

**Description**:
Add the three new dependencies (`flutter_riverpod`, `shared_preferences`, `fpdart`) and create the two core infrastructure files that every downstream task depends on.

1. Run `flutter pub add flutter_riverpod shared_preferences fpdart`
2. Create `lib/core/error/failures.dart` — a hand-written Dart 3 `sealed class Failure` with a single `CacheFailure` subclass (the only variant needed now; others are added by future features). This is the project's first `Failure` class, matching constitution §3.2.
3. Create `lib/core/providers/shared_preferences_provider.dart` — a `Provider<SharedPreferencesWithCache>` that throws `UnimplementedError` if accessed without being overridden in `main()`. This is the DI entry point for all SharedPreferences consumers.

**Change details**:
- `pubspec.yaml`: `flutter pub add` handles this — adds `flutter_riverpod`, `shared_preferences`, `fpdart` to dependencies
- `lib/core/error/failures.dart`:
  - Create `sealed class Failure` with `const Failure()` constructor
  - Create `class CacheFailure extends Failure` with `const CacheFailure(this.message)` and `final String message`
- `lib/core/providers/shared_preferences_provider.dart`:
  - Import `flutter_riverpod` and `shared_preferences`
  - Create `final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>((ref) => throw UnimplementedError(...))`

**Done when**:
- [ ] `flutter pub get` succeeds (all three packages resolve)
- [ ] `lib/core/error/failures.dart` exists with `sealed class Failure` and `CacheFailure` subclass
- [ ] `lib/core/providers/shared_preferences_provider.dart` exists with `sharedPreferencesProvider`
- [ ] `dart analyze lib/core/error/failures.dart lib/core/providers/shared_preferences_provider.dart` passes with zero issues

**Spec criteria addressed**: AC-7 (partial — core infrastructure for Clean Architecture persistence layer)

## Contracts

### Expects
- `pubspec.yaml` exists at project root with a `dependencies:` section
- `lib/core/` directory exists

### Produces
- `pubspec.yaml` contains `flutter_riverpod`, `shared_preferences`, and `fpdart` in `dependencies:`
- `lib/core/error/failures.dart` exports `sealed class Failure` and `class CacheFailure extends Failure`
- `lib/core/providers/shared_preferences_provider.dart` exports `final sharedPreferencesProvider` of type `Provider<SharedPreferencesWithCache>`
