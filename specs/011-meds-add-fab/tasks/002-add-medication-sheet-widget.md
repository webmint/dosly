### Task 002: Create AddMedicationSheet widget and its widget test

**Agent**: mobile-engineer
**Files**:
- `lib/features/meds/presentation/widgets/add_medication_sheet.dart` (create)
- `test/features/meds/presentation/widgets/add_medication_sheet_test.dart` (create)

**Depends on**: 001
**Blocks**: 003
**Context docs**: None
**Review checkpoint**: No

**Description**:
Create the placeholder Add-medication bottom-sheet widget consumed by the
Meds-screen FAB in Task 003. The widget is intentionally empty: a single
localized title rendered with `Theme.of(context).textTheme.titleLarge`
inside a `Padding(EdgeInsets.all(16))` wrapped in a `Column(mainAxisSize:
MainAxisSize.min)`. No buttons, fields, icons, or interactive controls —
this guard against scope creep is enforced by the accompanying widget
test.

The sheet's outer chrome (background color, rounded top corners, scrim,
elevation, drag-down dismissal) comes from `showModalBottomSheet`'s
Material 3 defaults at the Task 003 call site, NOT from this widget. The
widget body therefore should not include `SafeArea`, `Material`, or any
`backgroundColor:` property — `useSafeArea: true` on the call site
already handles bottom-inset padding for iOS notched devices.

**Change details**:
- In `lib/features/meds/presentation/widgets/add_medication_sheet.dart`:
  - Add `library;` directive with a top-of-file dartdoc explaining this
    is a placeholder until the real Add-medication flow ships in a
    future feature spec.
  - Import `package:flutter/material.dart`.
  - Import the localization extension via
    `import '../../../../l10n/l10n_extensions.dart';`.
  - Declare `class AddMedicationSheet extends StatelessWidget` with a
    `const AddMedicationSheet({super.key})` constructor.
  - In `build`, return `Padding(padding: const EdgeInsets.all(16),
    child: Column(mainAxisSize: MainAxisSize.min, children: [Text(
    context.l10n.medsAddTitle, style: Theme.of(context).textTheme.titleLarge)]))`.
  - Add `///` dartdoc on the class describing it as a placeholder
    bottom-sheet body and explicitly noting the future-spec replacement
    plan (so it satisfies the constitution's "no bare TODOs" rule
    without using a `TODO:` comment).
- In `test/features/meds/presentation/widgets/add_medication_sheet_test.dart`:
  - Import `flutter/material.dart`, `flutter_test/flutter_test.dart`,
    the project's `app_localizations.dart`, and the `AddMedicationSheet`
    under test.
  - Copy the `_resolveLocale` helper verbatim from
    `test/features/meds/presentation/screens/meds_screen_test.dart`
    (English-fallback resolver matching production). Add a brief
    comment referencing the alphabetical-fallback lesson
    (MEMORY.md, Feature 006).
  - Add a `_harness({required Locale locale})` helper that returns
    `MaterialApp(locale: locale, localizationsDelegates:
    AppLocalizations.localizationsDelegates, supportedLocales:
    AppLocalizations.supportedLocales, localeResolutionCallback:
    _resolveLocale, home: const Scaffold(body: AddMedicationSheet()))`.
    The `Scaffold` host is required so `Theme.of` resolves a real
    `TextTheme`.
  - `group('AddMedicationSheet locale switching', ...)` with three
    `testWidgets` covering `en` → "Add medication", `de` → "Medikament
    hinzufügen", `uk` → "Додати ліки". Each test asserts
    `find.text(<expected>)` resolves to one widget.
  - `group('AddMedicationSheet structure', ...)` with two
    `testWidgets`:
    - "renders exactly one Text" — pumps under English locale, asserts
      `find.descendant(of: find.byType(AddMedicationSheet), matching:
      find.byType(Text))` is `findsOneWidget`.
    - "has no interactive controls" — asserts each of
      `find.byType(ElevatedButton)`, `find.byType(OutlinedButton)`,
      `find.byType(TextButton)`, `find.byType(IconButton)`,
      `find.byType(TextField)`, `find.byType(Form)` is `findsNothing`.
  - `group('AddMedicationSheet typography', ...)` with one
    `testWidgets`: under English locale, locate the `Text` widget for
    "Add medication" and assert `(text.style?.fontSize ?? 0) == Theme.of(...)
    .textTheme.titleLarge?.fontSize`. Use a `Builder` inside the harness
    to capture `Theme.of` for the assertion, OR use
    `tester.widget<Text>(find.text('Add medication')).style` and compare
    via the `DefaultTextStyle.merge` semantics. Simpler approach: just
    assert the rendered Text widget's `style` is non-null and equals
    `Theme.of(elementFor(textWidget)).textTheme.titleLarge`.

**Done when**:
- [x] `lib/features/meds/presentation/widgets/add_medication_sheet.dart`
      exists with the structure described above and full dartdoc.
- [x] `test/features/meds/presentation/widgets/add_medication_sheet_test.dart`
      exists with the test groups described above.
- [x] `dart analyze 2>&1 | head -40` reports zero issues.
- [x] `flutter test test/features/meds/presentation/widgets/add_medication_sheet_test.dart`
      passes — all locale, structure, and typography tests green.

**Spec criteria addressed**: AC-4, AC-5, AC-9, AC-12

## Completion Notes
**Status**: Complete
**Completed**: 2026-04-29
**Files changed**: lib/features/meds/presentation/widgets/add_medication_sheet.dart (new), test/features/meds/presentation/widgets/add_medication_sheet_test.dart (new)
**Contract**: Expects 3/3 verified | Produces 5/5 verified
**Notes**: `dart analyze`: zero issues. `flutter test`: 176/176 (170 baseline + 6 new). Typography test used direct `==` comparison successfully (Flutter passes the same `TextStyle` reference from `Theme.of(...).textTheme.titleLarge`); no fontSize+fontWeight fallback needed. Code review: APPROVE WITH WARNINGS — two doc-consistency notes: the test's top-level `_resolveLocale` and `_harness` helpers use plain `//` comments instead of `///` dartdoc, while the sibling `meds_screen_test.dart` uses `///`. Cosmetic only; not blocking. If addressed later, ~4 lines of doc additions in `add_medication_sheet_test.dart`. Filed under "minor consistency drift" — track in MEMORY.md only if it recurs.

## Contracts

### Expects
- `AppLocalizations` (from `lib/l10n/app_localizations.dart`) declares
  `String get medsAddTitle` (produced by Task 001).
- `lib/l10n/l10n_extensions.dart` exists and provides
  `extension AppLocalizationsContext on BuildContext { AppLocalizations
  get l10n }`.
- `lib/features/meds/presentation/widgets/` directory either exists or
  can be created (no existing widget under `meds/`).

### Produces
- `lib/features/meds/presentation/widgets/add_medication_sheet.dart`
  exports `class AddMedicationSheet extends StatelessWidget` with a
  `const AddMedicationSheet({super.key})` constructor.
- `AddMedicationSheet.build` returns a widget tree that calls
  `context.l10n.medsAddTitle` for its only `Text` child.
- `AddMedicationSheet.build` references
  `Theme.of(context).textTheme.titleLarge` as the `Text` widget's
  `style`.
- `AddMedicationSheet.build` does NOT instantiate any of:
  `ElevatedButton`, `OutlinedButton`, `TextButton`, `IconButton`,
  `TextField`, `Form`, `SafeArea`, `Material` (the bottom-sheet route
  provides these where needed).
- `test/features/meds/presentation/widgets/add_medication_sheet_test.dart`
  exists and `flutter test` passes against it.
