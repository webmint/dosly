### Task 003: Wire FAB on MedsScreen, open AddMedicationSheet, extend screen test

**Agent**: mobile-engineer
**Files**:
- `lib/features/meds/presentation/screens/meds_screen.dart` (modify)
- `test/features/meds/presentation/screens/meds_screen_test.dart` (modify)

**Depends on**: 001, 002
**Blocks**: None
**Context docs**: None
**Review checkpoint**: Yes — convergence point (depends on Tasks 001 + 002) and integration gate for the full feature.

**Description**:
Add a Material 3 `FloatingActionButton` to `MedsScreen`'s `Scaffold`,
wire its `onPressed` to open `AddMedicationSheet` via
`showModalBottomSheet<void>`, and extend the existing screen test to
cover the new behavior. This task is the integration gate for the
feature — it gates on the full `flutter test` suite and `flutter build
apk --debug` per the integration-gate-on-terminal-task pattern
established in Features 002 / 005 / 007 (MEMORY.md).

The FAB MUST pass NO explicit `backgroundColor`, `foregroundColor`,
`elevation`, or `shape` arguments — the global
`floatingActionButtonTheme` in `lib/core/theme/app_theme.dart:81`
already maps them to `colorScheme.primaryContainer` /
`colorScheme.onPrimaryContainer` / `elevation: 0`. Likewise the
`showModalBottomSheet` call MUST pass NO explicit `backgroundColor`,
`shape`, `elevation`, or `barrierColor` — it relies on M3 defaults
(sheet background = `colorScheme.surfaceContainerLow`).

**Change details**:
- In `lib/features/meds/presentation/screens/meds_screen.dart`:
  - Update the library-level dartdoc to mention the FAB and that it
    opens a placeholder bottom sheet (the body is no longer empty
    once Task 003 lands).
  - Add `import 'package:lucide_icons_flutter/lucide_icons.dart';`.
  - Add `import '../widgets/add_medication_sheet.dart';`.
  - Add a private top-level helper:
    `void _openAddMedicationSheet(BuildContext context) { showModalBottomSheet<void>(context: context, useSafeArea: true, builder: (_) => const AddMedicationSheet()); }`
    Add a `///` dartdoc explaining the helper opens the placeholder
    sheet and notes the `useSafeArea: true` choice.
  - Update `MedsScreen.build` to add
    `floatingActionButton: FloatingActionButton(onPressed: () => _openAddMedicationSheet(context), tooltip: context.l10n.medsAddFabTooltip, child: const Icon(LucideIcons.plus))`
    on the existing `Scaffold`. Do NOT pass `backgroundColor`,
    `foregroundColor`, `elevation`, `shape`, or
    `floatingActionButtonLocation` — defaults flow from the theme.
  - Update the class-level dartdoc of `MedsScreen` to mention the FAB
    and the placeholder modal. Remove or amend the line that says
    "The body is `SizedBox.shrink` — empty until..." (the body is
    still empty, but the screen as a whole now has visible affordances
    — adjust wording to "The Scaffold body remains `SizedBox.shrink`;
    the FAB launches a placeholder bottom sheet via
    `_openAddMedicationSheet`.").
- In `test/features/meds/presentation/screens/meds_screen_test.dart`:
  - Keep the existing two groups (`MedsScreen locale switching`,
    `MedsScreen AppBar shape`) intact — those AppBar assertions still
    hold and provide regression coverage.
  - Add a new `group('MedsScreen FAB', ...)` with three
    `testWidgets`:
    - "renders a FloatingActionButton" — `find.byType(FloatingActionButton)`
      is `findsOneWidget`.
    - "FAB tooltip is the localized medsAddFabTooltip for en/de/uk" —
      one test per locale, asserting
      `tester.widget<FloatingActionButton>(find.byType(FloatingActionButton)).tooltip`
      equals "Add medication" / "Medikament hinzufügen" / "Додати ліки".
    - "FAB child is a Lucide plus Icon" — assert the FAB's child is an
      `Icon` whose `icon` field equals `LucideIcons.plus`.
  - Add a new `group('MedsScreen Add-medication modal', ...)` with two
    `testWidgets`:
    - "tapping the FAB opens a bottom sheet showing the localized
      title (en)" — pump under `Locale('en')`,
      `await tester.tap(find.byType(FloatingActionButton))`,
      `await tester.pumpAndSettle()`,
      `expect(find.text('Add medication'), findsAtLeastNWidgets(1))`,
      `expect(find.byType(AddMedicationSheet), findsOneWidget)`.
    - "modal closes via tap on the scrim (Navigator.pop equivalent)" —
      open the sheet as above, then call
      `Navigator.of(tester.element(find.byType(AddMedicationSheet))).pop()`,
      `await tester.pumpAndSettle()`,
      `expect(find.byType(AddMedicationSheet), findsNothing)`. (We
      cannot tap the scrim by coordinate reliably across screen sizes;
      asserting `Navigator.pop` works is the equivalent invariant.)
  - Add the import `import 'package:dosly/features/meds/presentation/widgets/add_medication_sheet.dart';`.
  - Add the import `import 'package:lucide_icons_flutter/lucide_icons.dart';`.

**Done when**:
- [x] `MedsScreen.build` returns a `Scaffold` whose
      `floatingActionButton` is a non-null `FloatingActionButton` with
      no explicit color/shape/elevation parameters.
- [x] Tapping the FAB opens an `AddMedicationSheet` instance via
      `showModalBottomSheet<void>`.
- [x] `dart analyze 2>&1 | head -40` reports zero issues across the
      whole project.
- [x] `flutter test` passes for the entire project (existing tests +
      new groups).
- [x] `flutter build apk --debug` succeeds with no errors.

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-6, AC-9, AC-10, AC-11, AC-13, AC-14, AC-15 (code path only — no manual emulator step), AC-16 (code path only — no manual emulator step)

## Completion Notes
**Status**: Complete
**Completed**: 2026-04-29
**Files changed**: lib/features/meds/presentation/screens/meds_screen.dart (modify), test/features/meds/presentation/screens/meds_screen_test.dart (modify)
**Contract**: Expects 4/4 verified | Produces 6/6 verified
**Notes**: `dart analyze`: zero issues. `flutter test`: 183/183 PASS (176 → 183, +7 new). `flutter build apk --debug`: SUCCESS. Test split: FAB group has 5 tests (presence, icon, tooltip×3 locales — separate testWidgets per locale), Add-medication modal group has 2 tests (tap-opens-sheet, Navigator.pop dismisses). All consume the `!`-free patterns: `context.l10n.medsAddFabTooltip` for the tooltip, `tester.widget<Icon>(find.descendant(...))` for icon retrieval, `tester.element(find.byType(AddMedicationSheet))` for `Navigator.of(...)`. Code review verdict: **APPROVE** with zero findings. Aggregate audit across Tasks 001+002+003: zero new `!`, zero `// ignore:`, zero color literals, zero bare TODOs. Integration sound end-to-end (FAB → showModalBottomSheet → AddMedicationSheet → context.l10n → theme).

## Contracts

### Expects
- `AppLocalizations` exposes `String get medsAddFabTooltip` (produced
  by Task 001).
- `AddMedicationSheet` exists at
  `lib/features/meds/presentation/widgets/add_medication_sheet.dart`
  with a `const AddMedicationSheet({super.key})` constructor (produced
  by Task 002).
- `lib/core/theme/app_theme.dart` declares a
  `floatingActionButtonTheme` mapping `backgroundColor` →
  `scheme.primaryContainer`, `foregroundColor` →
  `scheme.onPrimaryContainer`, `elevation` → `0` (already present at
  `app_theme.dart:81` — pre-existing codebase state).
- `pubspec.yaml` pins `lucide_icons_flutter: ^3.1.12` and
  `LucideIcons.plus` is exported from
  `package:lucide_icons_flutter/lucide_icons.dart` (already present —
  used in `theme_preview_screen.dart:68`).

### Produces
- `lib/features/meds/presentation/screens/meds_screen.dart` imports
  `package:lucide_icons_flutter/lucide_icons.dart` and
  `'../widgets/add_medication_sheet.dart'`.
- `meds_screen.dart` declares a private top-level function
  `void _openAddMedicationSheet(BuildContext context)` whose body
  calls `showModalBottomSheet<void>(context: context, useSafeArea:
  true, builder: (_) => const AddMedicationSheet())`.
- `MedsScreen.build` returns a `Scaffold` whose `floatingActionButton`
  is a `FloatingActionButton` whose `tooltip` equals
  `context.l10n.medsAddFabTooltip` and whose `child` is `const
  Icon(LucideIcons.plus)`.
- `MedsScreen.build` does NOT pass `backgroundColor`,
  `foregroundColor`, `elevation`, `shape`, or
  `floatingActionButtonLocation` arguments to
  `FloatingActionButton` or `Scaffold` (theme defaults flow through).
- `test/features/meds/presentation/screens/meds_screen_test.dart`
  contains a `group('MedsScreen FAB', ...)` with at least three
  `testWidgets` and a `group('MedsScreen Add-medication modal', ...)`
  with at least two `testWidgets`.
- `flutter test` passes for the full project; `flutter build apk
  --debug` succeeds.
