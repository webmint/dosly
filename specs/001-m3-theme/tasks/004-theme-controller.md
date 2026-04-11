# Task 004: Create theme_controller.dart and its tests

**Agent**: mobile-engineer
**Files**:
- `lib/core/theme/theme_controller.dart` *(create)*
- `test/core/theme/theme_controller_test.dart` *(create)*

**Depends on**: None
**Blocks**: 007 (preview screen calls `themeController.cycle()`), 008 (DoslyApp listens to themeController)
**Review checkpoint**: No
**Context docs**: None

## Description

Create a `ThemeController` that holds the current `ThemeMode` and notifies listeners on change. Subclasses `ValueNotifier<ThemeMode>` so it integrates cleanly with `ListenableBuilder` in `DoslyApp`. Default value is `ThemeMode.system`. Exposes a `setMode(ThemeMode)` method (which is just a wrapper around the `value` setter for symmetry) and a `cycle()` method that advances `system → light → dark → system`. A top-level `final themeController = ThemeController();` provides the singleton consumed by the rest of the app.

In-memory only — no persistence. Spec Section 6 explicitly excludes that.

## Change details

- Create `lib/core/theme/theme_controller.dart`:
  - `import 'package:flutter/foundation.dart';` (`ValueNotifier`)
  - `import 'package:flutter/material.dart';` (`ThemeMode`)
  - File header dartdoc.
  - Class `ThemeController extends ValueNotifier<ThemeMode>`:
    - Constructor: `ThemeController() : super(ThemeMode.system);`
    - Method `void setMode(ThemeMode mode)` → just `value = mode;`
    - Method `void cycle()` → reads `value`, picks the next mode in the order `system → light → dark → system`, and sets `value` to it.
    - Dartdoc on the class and on each method (`///` style).
  - Top-level `final ThemeController themeController = ThemeController();`
  - Add a `///` comment on the singleton noting "In-memory only — resets to ThemeMode.system on every restart. Persistence is the future Settings feature's responsibility."

- Create `test/core/theme/theme_controller_test.dart`:
  - `import 'package:flutter/material.dart';`
  - `import 'package:flutter_test/flutter_test.dart';`
  - `import 'package:dosly/core/theme/theme_controller.dart';`
  - Tests (each instantiates a fresh `ThemeController()`, NOT the singleton, so tests don't share state):
    1. `'default value is ThemeMode.system'` → expect `controller.value == ThemeMode.system`
    2. `'setMode updates value'` → call `controller.setMode(ThemeMode.dark)`, expect `controller.value == ThemeMode.dark`
    3. `'setMode notifies listeners'` → register a listener with `addListener`, call `setMode`, expect listener to have been called once
    4. `'cycle advances system → light'` → fresh controller, call `cycle()`, expect `value == ThemeMode.light`
    5. `'cycle advances light → dark'` → set to light, call `cycle()`, expect `value == ThemeMode.dark`
    6. `'cycle advances dark → system'` → set to dark, call `cycle()`, expect `value == ThemeMode.system`
    7. `'three cycles return to start'` → fresh controller, call `cycle()` three times, expect `value == ThemeMode.system`

## Done when

- [x] `lib/core/theme/theme_controller.dart` exists with class `ThemeController extends ValueNotifier<ThemeMode>`
- [x] Top-level `final themeController = ThemeController();` exists
- [x] `cycle()` cycles through `system → light → dark → system`
- [x] `test/core/theme/theme_controller_test.dart` exists with all 7 tests above
- [x] `flutter test test/core/theme/theme_controller_test.dart` passes (7/7)
- [x] `dart analyze` is clean

## Spec criteria addressed

AC-6, AC-12 (this test file's portion)

## Completion Notes

**Status**: Complete
**Completed**: 2026-04-11
**Files changed**:
- `lib/core/theme/theme_controller.dart` (created)
- `test/core/theme/theme_controller_test.dart` (created)

**Contract**: Expects 1/1 verified | Produces 6/6 verified

**Notes**:
- 7/7 tests pass on first run.
- Deviation: removed `import 'package:flutter/foundation.dart';` because `ValueNotifier` is re-exported through `material.dart`, and `unnecessary_import` lint would have failed `dart analyze`. Functionality unchanged.
- Used Dart 3 exhaustive `switch` expression in `cycle()` (no `default:` clause) per constitution §3.1 / §4.1.1.
- Code review skipped (mechanical, matches spec exactly, single small file with simple state).

## Contracts

### Expects
- `package:flutter/foundation.dart` and `package:flutter/material.dart` are available

### Produces
- File `lib/core/theme/theme_controller.dart` exists
- It declares `class ThemeController extends ValueNotifier<ThemeMode>`
- It declares a method `void setMode(ThemeMode mode)`
- It declares a method `void cycle()`
- It declares a top-level `final ThemeController themeController` (not inside the class — must be importable as `themeController` from outside)
- File `test/core/theme/theme_controller_test.dart` exists and imports `package:dosly/core/theme/theme_controller.dart`
