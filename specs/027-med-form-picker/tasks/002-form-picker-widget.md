# Task 002: Build the form picker and insert it into AddMedicationModal

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/widgets/add_medication_modal.dart`
**Depends on**: 001
**Blocks**: 003
**Context docs**: None (design source: `dosly_m3_template.html` `.form-picker-display` `:783–818` / `.form-picker-grid-card` `:820–869`, markup `:2011–2077`)
**Review checkpoint**: Yes

## Description

Add a self-contained, **presentation-only** medication-form picker to the Add-medication modal, inserted into the existing body `Column` **between** the name `TextField` and the Save `FilledButton`. The picker is a private `StatefulWidget` (`_MedicationFormPicker`) that owns its own selection + open/closed state via `setState`. It renders a tappable display row (outlined, with a floating label, an icon chip, a name + sub line, and a rotating chevron) that expands an animated grid of **8** form chips. Selecting a chip highlights it, updates the display row, and collapses the grid. **No domain/data, no Riverpod, no persistence** — the selection is intentionally unconsumed this iteration; the Save button stays the documented no-op from spec 026.

This is the first use of `InputDecorator`, `AnimatedSize`, `AnimatedRotation`, and `InkWell` in the project — all Flutter built-ins, no new dependency.

## Change details

In `lib/features/meds/presentation/widgets/add_medication_modal.dart`:

- **Presentation-only forms data**: add a private immutable value type and a top-level `final` list of the 8 forms, in HTML grid order (`tablet, capsule, syrup, drops, injection, inhaler, cream, sachet`):
  ```dart
  @immutable
  class _MedFormOption {
    const _MedFormOption({required this.key, required this.icon, required this.name, required this.sub});
    final String key;                                 // stable id (matches PLANNED domain enum name)
    final IconData icon;                              // Lucide icon (Material fallback if a name fails)
    final String Function(AppLocalizations l10n) name;
    final String Function(AppLocalizations l10n) sub;
  }
  final List<_MedFormOption> _medFormOptions = [ /* 8 entries */ ];
  ```
  Icon mapping (verify each compiles; if a Lucide name does not exist, use the sanctioned Material `Icons.*` fallback — spec §7): `tablet`→`LucideIcons.pills`, `capsule`→`LucideIcons.pill`, `syrup`→`LucideIcons.milk`, `drops`→`LucideIcons.droplets`, `injection`→`LucideIcons.syringe`, `inhaler`→`LucideIcons.wind`, `cream`→ verify (e.g. `LucideIcons.container`, else `Icons.healing`), `sachet`→`LucideIcons.package` (else `Icons.inventory_2_outlined`). Map `name`/`sub` to the `l.medsAddForm<Name>` / `l.medsAddForm<Name>Sub` getters.
- **`_MedicationFormPicker` (private `StatefulWidget`)**:
  - State fields: `int? _selectedIndex;` (null = no selection) and `bool _isOpen = false;`.
  - **Display row**: an `InkWell`/`GestureDetector` (onTap toggles `_isOpen` via `setState`) wrapping an `InputDecorator(decoration: InputDecoration(labelText: context.l10n.medsAddFormLabel), isEmpty: false, child: <row>)`. The row is a `Row` of: a leading icon chip (`Container`, `colorScheme.secondaryContainer` background, rounded ~8px, icon in `colorScheme.onSecondaryContainer`); an `Expanded` `Column` with a name line and a sub line; a trailing chevron (`LucideIcons.chevronDown`) wrapped in `AnimatedRotation(turns: _isOpen ? 0.5 : 0)`.
  - Before selection (`_selectedIndex == null`): name line = `context.l10n.medsAddFormPlaceholder`, sub line empty, a neutral placeholder icon (any compiling glyph). After selection: read `_medFormOptions[_selectedIndex!]` — but **do not use `!`**; resolve via a local non-null binding (e.g. `final i = _selectedIndex; if (i != null) ...`) or store the selected `_MedFormOption?` directly.
  - **Grid (animated)**: wrap in `AnimatedSize` (duration ~250–300 ms) whose child is **conditionally built** — `SizedBox.shrink()` when `!_isOpen`, otherwise the grid card. (Conditional build, not clip, so the options are absent from the tree when collapsed — clean for testing.)
  - **Grid card**: a `Container`/`Material` with `colorScheme.primaryContainer` background and rounded bottom corners (~16px), containing a title `Text(context.l10n.medsAddFormGridTitle)` (uppercase styling via `textTheme.labelMedium` + `color: colorScheme.primary`) and a **2-column** layout: a `Column` of `Row`s pairing the 8 options, each option in an `Expanded` with a small gap between columns.
  - **Option chip**: an `InkWell` (onTap: `setState(() { _selectedIndex = i; _isOpen = false; })`) over a `Container(BoxDecoration)`. Unselected: `colorScheme.surfaceContainerLow` (or `surface`) background, transparent border, icon + label in `onSurface`/`onSurfaceVariant`. Selected (`i == _selectedIndex`): `colorScheme.primary` background + border, icon + label in `colorScheme.onPrimary`. Show the option's `icon` + its localized `name`.
- **Insertion**: in `_AddMedicationModalState.build`, add `const _MedicationFormPicker()` (plus spacing `SizedBox`) into the body `Column`, **after** the name `TextField` and **before** the `SizedBox(height: 16)` + Save `FilledButton`.
- **Dartdoc**: update the library/`AddMedicationModal` dartdoc to mention the form picker; add `///` to `_MedicationFormPicker` noting it is visual-only iteration 2 (spec 027), the selection is local and intentionally not persisted/consumed, and Save remains a no-op.
- **No** `package:flutter_riverpod` import, **no** `ConsumerStatefulWidget`, **no** `drift`/domain/data imports, **no** hardcoded color literals (all via `Theme.of(context).colorScheme`).

## Contracts

### Expects
- `lib/l10n/app_localizations.dart` declares getters `medsAddFormLabel`, `medsAddFormPlaceholder`, `medsAddFormGridTitle`, and the 8 `medsAddForm<Name>` + 8 `medsAddForm<Name>Sub` getters (from Task 001).
- `add_medication_modal.dart` has `_AddMedicationModalState.build` returning a `Scaffold` whose body `Column` contains the name `TextField` and the Save `FilledButton.icon` (spec 026).

### Produces
- `add_medication_modal.dart` declares a private widget `class _MedicationFormPicker extends StatefulWidget`.
- `add_medication_modal.dart` declares `class _MedFormOption` and a `_medFormOptions` list with exactly 8 entries.
- `_AddMedicationModalState.build` references `_MedicationFormPicker` (the picker is mounted in the body between the `TextField` and the `FilledButton`).
- The file reads `context.l10n.medsAddFormLabel`, `context.l10n.medsAddFormPlaceholder`, and `context.l10n.medsAddFormGridTitle`.
- The file contains no `ConsumerStatefulWidget`, no `flutter_riverpod` import, and no `!` null-assertion operator; no `lib/features/meds/domain/` or `.../data/` file is created; `pubspec.yaml` is unchanged.

## Done when
- [x] `_MedicationFormPicker` renders a tappable display row (label, icon chip, name, sub, chevron) and, when open, a grid of exactly 8 options with the grid title.
- [x] On first build the picker is collapsed with the placeholder text and no option selected; tapping the row toggles the grid; tapping an option selects exactly one, updates the display row, and collapses the grid.
- [x] All picker strings come from `context.l10n`; all colors from `Theme.of(context).colorScheme`; no `!`, no Riverpod, no domain/data, no `pubspec.yaml` change.
- [x] The name `TextField` and the Save `FilledButton` (no-op) are unchanged; the picker uses neither a `TextField` nor a `FilledButton`.
- [x] `dart analyze` passes on the changed file (zero issues; no lint-suppression comments).
- [x] The existing `add_medication_modal_test.dart` suite still passes unchanged (`flutter test`).
- [x] `flutter build apk --debug` succeeds.

## Spec criteria addressed
AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-11, AC-12, AC-15

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-13
**Files changed**: lib/features/meds/presentation/widgets/add_medication_modal.dart
**Contract**: Expects [2/2 verified] | Produces [6/6 verified] — `_MedicationFormPicker` StatefulWidget, `_MedFormOption` + 8-entry `_medFormOptions`, picker mounted between TextField and FilledButton, reads medsAddFormLabel/Placeholder/GridTitle, no Riverpod/`!`/domain/data, pubspec unchanged
**Verification**: dart analyze clean; flutter test 295 pass; flutter build apk --debug succeeded
**Code review**: APPROVE WITH WARNINGS → all 4 addressed (W1 dead ternary removed, W2 const-comment added, W3 surfaceContainerLow→Lowest, W4 title gap 8→10)
**Notes**: Icon gotcha (as predicted): `LucideIcons.pills` does NOT exist in 3.1.12 → used `LucideIcons.tablets` (semantically correct). `LucideIcons.container` (cream) and `LucideIcons.package` (sachet) BOTH exist — no Material fallback needed. Placeholder icon = `LucideIcons.shapes`. Grid is conditionally built (SizedBox.shrink when collapsed) so options are absent from the tree → clean for Task 003 testing.
