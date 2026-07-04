# Task 001: Create IntakeWindow and GracePeriod value objects

**Agent**: architect
**Files**: `lib/features/settings/domain/value_objects/intake_window.dart` (new), `lib/features/settings/domain/value_objects/grace_period.dart` (new)
**Depends on**: None
**Blocks**: 002, 003, 004
**Context docs**: `specs/039-intake-settings/data-model.md`
**Review checkpoint**: No

**Description**:
Introduce two immutable, self-clamping value objects that model the two numeric intake settings. Each wraps a single `int minutes`, clamps to its valid range at construction, and exposes a compile-time-`const` default so it can be used as a freezed `@Default` on `AppSettings` (Task 003). Hand-rolled (not freezed): a clamping smart constructor is a factory with a body and can never be `const`, but `@Default` requires a const value — so a private `const` unclamped constructor plus a `static const defaultValue` is the clean solution.

**Change details**:
- In `lib/features/settings/domain/value_objects/intake_window.dart`:
  - `class IntakeWindow` with `final int minutes`.
  - `static const int minMinutes = 15;` `static const int maxMinutes = 240;`
  - `const IntakeWindow._(this.minutes);` (private, unclamped — only for known-valid/const values).
  - `factory IntakeWindow(int minutes) => IntakeWindow._(minutes.clamp(minMinutes, maxMinutes));`
  - `static const IntakeWindow defaultValue = IntakeWindow._(120);`
  - Override `operator ==` (value equality on `minutes`) and `hashCode`; add `toString()`.
  - Dartdoc on the class, the range, the factory, and `defaultValue`.
- In `lib/features/settings/domain/value_objects/grace_period.dart`:
  - Same shape as `IntakeWindow` with `minMinutes = 0`, `maxMinutes = 30`, `defaultValue = GracePeriod._(5)`.

**Contracts**:

### Expects
- No symbol named `IntakeWindow` or `GracePeriod` exists under `lib/`.
- `lib/features/settings/domain/` exists (the settings domain layer is present).

### Produces
- `lib/features/settings/domain/value_objects/intake_window.dart` declares `class IntakeWindow` with `final int minutes`, `factory IntakeWindow(int minutes)`, `const IntakeWindow._(`, `static const int minMinutes = 15`, `static const int maxMinutes = 240`, and `static const IntakeWindow defaultValue`.
- `lib/features/settings/domain/value_objects/grace_period.dart` declares `class GracePeriod` with `final int minutes`, `factory GracePeriod(int minutes)`, `const GracePeriod._(`, `static const int minMinutes = 0`, `static const int maxMinutes = 30`, and `static const GracePeriod defaultValue`.
- Both files declare `bool operator ==(` and `int get hashCode`.
- Neither file contains `package:flutter`, `package:drift`, or `data/` in an import.

**Done when**:
- [x] `IntakeWindow(10).minutes == 15`, `IntakeWindow(500).minutes == 240`, `IntakeWindow(120).minutes == 120`; two equal-minute instances are `==`.
- [x] `GracePeriod(-1).minutes == 0`, `GracePeriod(99).minutes == 30`, `GracePeriod(5).minutes == 5`; value equality holds.
- [x] `IntakeWindow.defaultValue.minutes == 120` and `GracePeriod.defaultValue.minutes == 5`, both usable in a `const` context.
- [x] No Flutter/drift/data imports (domain purity).
- [x] `dart analyze` passes on both files.

**Spec criteria addressed**: AC-2, AC-3, AC-4 (supports AC-1)

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-03
**Files changed**: `lib/features/settings/domain/value_objects/intake_window.dart` (new), `grace_period.dart` (new)
**Contract**: Expects [2/2 verified] | Produces [all verified]
**Code review**: APPROVE (1 cosmetic format warning on `grace_period.dart` — fixed via `dart format`)
**Notes**: Hand-rolled (no freezed) per the approved plan decision — clamping factory can't be `const`, but `@Default` needs a const `defaultValue`. Zero imports (pure Dart). `int.clamp(int,int)` returns `int`, so the MEMORY `clamp()`→`num` pitfall doesn't bite.
