# Spec: Add-Medication Name Field + Save Button (visual-only, iteration 1)

**Date**: 2026-06-11
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

This is **iteration 1** of building the Add-medication form, deliberately scoped to **visuals only**. It replaces the empty body of the existing `AddMedicationModal` with two controls from the design's "Screen 3 — Add / Edit Medication": an outlined **medication-name text field** and a **Save button**. No data is captured, validated, or persisted — the Save button is a **no-op** this iteration. The full form (form picker, dose, schedule, intake type) and actual data persistence (domain entity, repository, drift) arrive in later iterations, with data-save being the final one.

## 2. Current State

**The modal** (`lib/features/meds/presentation/widgets/add_medication_modal.dart:26`) is a `StatelessWidget` named `AddMedicationModal`. Its `build` returns a `Scaffold` whose `appBar` is an `AppBar` with a back-arrow `IconButton` leading (`LucideIcons.arrowLeft` → `Navigator.pop`), a `MaterialLocalizations.backButtonTooltip`, and a `title` of `Text(context.l10n.medsAddTitle)`. The `body` is `const SizedBox.shrink()` (intentional placeholder per spec 011). It is pushed as a full-screen modal route via `Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(fullscreenDialog: true, ...))` from `meds_screen.dart:61`. **No change to the trigger, routing, AppBar, or push mechanics is needed.**

**The FAB trigger** (`lib/features/meds/presentation/screens/meds_screen.dart:43`) already opens the modal — out of scope to touch.

**Text input is new to the project.** A repo-wide search confirms **no** `TextField`, `TextFormField`, `TextEditingController`, or `Form` exists anywhere in `lib/`. This is the first text input in dosly. Consequence: the modal must become a `StatefulWidget` so it can own a `TextEditingController` and dispose it in `dispose()`.

**No persistence layer exists.** `drift`/`sqlite` are not in `pubspec.yaml`; there is no `Medication` entity, repository, data source, use case, or provider in `lib/features/meds/`. The meds feature today is only `screens/meds_screen.dart` + `widgets/add_medication_modal.dart` (presentation only). This iteration adds **nothing** to `domain/` or `data/`.

**Localization** (`lib/l10n/app_{en,de,uk}.arb` + `l10n_extensions.dart`) follows the established `flutter gen-l10n` 3-locale pattern: keys live in all three ARB files, `@`-description metadata lives only in `app_en.arb` (the template locale), and strings are read via the `context.l10n` extension (the single sanctioned `AppLocalizations.of(context)!` site). Existing meds keys: `medsAddFabTooltip`, `medsAddTitle`. Generated bindings (`app_localizations*.dart`) are produced by `flutter gen-l10n` and must not be hand-edited.

**Theme.** The global Material 3 theme (`lib/core/theme/app_theme.dart`) drives all chrome. A `FilledButton` and an `OutlineInputBorder` `TextField` render correct light/dark colors with no call-site overrides. The design's text field (`dosly_m3_template.html:894-908`, class `.fi`) is a 56px-tall outlined field with a 2px primary border and a floating label on the surface — a textbook M3 `TextField` with `labelText` + `OutlineInputBorder`. The design's Save button (`dosly_m3_template.html:2231`, class `.btn-filled`) is a full-width filled button with a leading save icon and the text "Зберегти" — maps to `FilledButton.icon(icon: Icon(LucideIcons.save), label: Text(...))`.

**Lucide icons** (`lucide_icons_flutter: ^3.1.12`) are the project icon set; `LucideIcons.plus` and `LucideIcons.arrowLeft` are already used in this exact modal/screen. The Save glyph is `LucideIcons.save` (the design's save SVG path is the canonical Lucide `save`). _Note (MEMORY): `save` is not in the verified-name list — confirm it compiles; if not, the fallback is `Icons.save_outlined`._

**Existing test** (`test/features/meds/presentation/widgets/add_medication_modal_test.dart`) asserts the body is empty: a group `AddMedicationModal structure` with a test `body is empty (SizedBox.shrink)` that asserts `find.byType(TextField)`, `find.byType(Form)`, and three button types all resolve to `findsNothing`, and that `scaffold.body` is a bare `SizedBox`. These assertions will break once the field + button are added and **must be updated in the same task**. The locale-switching and AppBar/back-arrow/title-typography assertions stay valid and must continue to pass unchanged.

## 3. Desired Behavior

1. **Modal becomes stateful**
   - `AddMedicationModal` is converted from `StatelessWidget` to `StatefulWidget` (plain `StatefulWidget` — **not** `ConsumerStatefulWidget`; no Riverpod is needed this iteration).
   - Its `State` owns a single `final TextEditingController` for the name field, created in `initState` (or as a field initializer) and disposed in `dispose()`.
   - The `AppBar` (back-arrow leading, `backButtonTooltip`, `Text(context.l10n.medsAddTitle)` title) is **unchanged** in structure and behavior.

2. **Body: medication-name field**
   - The Scaffold `body` changes from `SizedBox.shrink()` to a **scrollable** container (`SingleChildScrollView`) holding a `Column` with horizontal padding (16 px, matching the design's `.form-sec`), so the keyboard cannot cause a layout overflow.
   - The first child is a `TextField` bound to the name controller, decorated with `InputDecoration(labelText: context.l10n.medsAddNameLabel, border: OutlineInputBorder())`. No explicit colors, fill, or text style at the call site — styling flows from the global theme.
   - The field is a plain `TextField` (no `Form`, no `TextFormField`, no validator) — there is no validation this iteration.

3. **Body: Save button**
   - Below the field, a `FilledButton.icon` with `icon: Icon(LucideIcons.save)` and `label: Text(context.l10n.medsAddSaveButton)`.
   - The button is **full-width** (matching the design's full-width `.btn-filled`), e.g. wrapped so it stretches to the available width.
   - The button is **always enabled** (no disable-until-non-empty gating — that is validation, deferred).
   - **`onPressed` is a no-op** this iteration: it does **not** read the field, validate, persist, navigate, pop the modal, or show any feedback. It must be a non-null callback (so the button renders enabled per the design) that performs no action. _A single-line dartdoc/comment must state the no-op is intentional and reference this spec, per the constitution's "no bare TODO / never swallow" rules._

4. **Theme & localization correctness**
   - The field and button render correct M3 colors in both light and dark themes with zero call-site color overrides (theme-driven).
   - All visible strings (`medsAddNameLabel`, `medsAddSaveButton`) are reached via `context.l10n`; no `AppLocalizations.of(context)!` at the call site.

5. **New localization keys**
   - `medsAddNameLabel` — floating label for the name field.
     - EN: `Medication name` · DE: `Medikamentenname` · UK: `Назва ліків`
   - `medsAddSaveButton` — label on the Save button.
     - EN: `Save` · DE: `Speichern` · UK: `Зберегти`
   - Both keys exist in all three ARB files; `@`-description metadata for both exists only in `app_en.arb`. Bindings regenerated via `flutter gen-l10n` (not hand-edited).

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Meds presentation — modal | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Convert to `StatefulWidget`; add a `TextEditingController` (disposed in `dispose`); replace `SizedBox.shrink` body with a scrollable padded `Column` containing the name `TextField` + a full-width `FilledButton.icon` Save (no-op `onPressed`). AppBar unchanged. Update dartdoc to describe the new body + the intentional no-op. |
| L10n — English template | `lib/l10n/app_en.arb` | Add `medsAddNameLabel` + `medsAddSaveButton` with `@`-description metadata for each. |
| L10n — German | `lib/l10n/app_de.arb` | Add the two keys with the values from §3.5. |
| L10n — Ukrainian | `lib/l10n/app_uk.arb` | Add the two keys with the values from §3.5. |
| L10n — generated bindings | `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` | Regenerated by `flutter gen-l10n` (do not hand-edit). |
| Meds tests — modal | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Replace the `body is empty (SizedBox.shrink)` test with assertions for the new body (field present with localized label, Save button present with localized label + `LucideIcons.save`, no-op tap is harmless). Keep the locale-switching, back-arrow, and title-typography tests passing unchanged. |

**No changes** to `meds_screen.dart`, the routing shell, the theme, `pubspec.yaml`, or any `domain/` or `data/` code.

## 5. Acceptance Criteria

- [x] **AC-1**: `AddMedicationModal` is a `StatefulWidget` whose `State` declares a `TextEditingController` and disposes it in `dispose()`.
- [x] **AC-2**: The Scaffold `body` is no longer `SizedBox.shrink`; it is a scrollable container (`SingleChildScrollView`) whose subtree contains exactly one `TextField` and exactly one `FilledButton` (the Save button). The `AppBar` and its back-arrow leading + `medsAddTitle` title are unchanged.
- [x] **AC-3**: The `TextField`'s `InputDecoration` uses `labelText: context.l10n.medsAddNameLabel` and an `OutlineInputBorder`, with no explicit color/fill/text-style overrides at the call site.
- [x] **AC-4**: The Save button is a `FilledButton.icon` whose icon is `LucideIcons.save` and whose label text is `context.l10n.medsAddSaveButton`, rendered full-width. _(If `LucideIcons.save` does not compile, `Icons.save_outlined` is the sanctioned fallback — see §8.)_
- [x] **AC-5**: The Save button is enabled (non-null `onPressed`), and its `onPressed` performs **no** action — it does not read the controller, validate, persist, navigate, pop, or show feedback. The no-op is documented inline with a reference to this spec (no bare TODO).
- [x] **AC-6**: Two new ARB keys `medsAddNameLabel` and `medsAddSaveButton` exist in all three ARB files (`app_en.arb`, `app_de.arb`, `app_uk.arb`) with the EN/DE/UK values from §3.5.
- [x] **AC-7**: `app_en.arb` includes `@medsAddNameLabel` and `@medsAddSaveButton` description-metadata blocks per the existing convention; DE/UK ARBs contain values only (no `@` blocks).
- [x] **AC-8**: All new strings in widget code are reached via `context.l10n` — no `AppLocalizations.of(context)!` and no `!` null assertion at the call site.
- [x] **AC-9**: `dart analyze` passes on all changed/created files with zero warnings or errors (strict-mode lint config preserved; no lint-suppression comments).
- [x] **AC-10**: `add_medication_modal_test.dart` no longer asserts the body is `SizedBox.shrink`; it asserts (a) a `TextField` is present whose decoration `labelText` equals the localized `medsAddNameLabel`, (b) a `FilledButton` is present whose visible text equals the localized `medsAddSaveButton` and whose icon is `LucideIcons.save`, and (c) tapping the Save button completes without throwing and does not pop the modal. The existing locale-switching (en/de/uk title), back-arrow-leading, and title-typography tests remain and pass unchanged.
- [x] **AC-11**: `flutter test` passes for the full project.
- [x] **AC-12**: `flutter build apk --debug` succeeds.
- [ ] **AC-13** _(manual, gated by /verify reading code only)_: Running the app, opening the modal, and toggling Settings → Appearance between Light and Dark shows the field outline/label and the Save button swapping to the matching theme colors with no visual glitch; switching Settings → Language updates the field label and Save button text to the corresponding localized string on the next open of the modal.

## 6. Out of Scope

- **NOT included**: any persistence — no drift dependency, table, migration, repository, data source, or write. The entered name is discarded.
- **NOT included**: any `domain/` or `data/` code for meds — no `Medication` entity, value object, use case, abstract repository, or provider. This iteration touches only `presentation/`.
- **NOT included**: any Riverpod provider or `ConsumerStatefulWidget` — the modal stays a plain `StatefulWidget`.
- **NOT included**: validation of the name (non-empty, length, trimming, dedupe), disable-until-valid gating of the Save button, or any error/helper text on the field.
- **NOT included**: Save-button behavior of any kind (pop, navigate, snackbar, clear field) — it is a documented no-op.
- **NOT included**: the rest of the HTML "Screen 3" form — form picker (8 medication forms), dose + unit, quantity stepper, stock card, time chips, intake type (Permanent/Course) and course parameters. These are later visual iterations.
- **NOT included**: pre-filling the field for an "edit" flow, or any edit-vs-add distinction (the HTML screen is "Add / Edit"; only the add-empty visual is in scope).
- **NOT included**: changing the modal's AppBar, title, back-arrow, push mechanics (`rootNavigator`/`fullscreenDialog`), or the Meds-screen FAB.
- **NOT included**: keyboard "done"/`onSubmitted` handling, input formatters, autofocus decisions beyond what the default `TextField` provides.

## 7. Technical Constraints

- **Constitution compliance**:
  - No Flutter imports added to `domain/` (not relevant — no domain code is touched).
  - No `!` null assertion in widget code; reach strings via `context.l10n`.
  - All new/changed public widgets retain accurate dartdoc `///` comments.
  - The intentional no-op `onPressed` must be documented (constitution: "never leave bare TODOs", "never swallow"); an empty callback with a clear comment referencing this spec satisfies this — it is not a swallowed error.
  - `dart analyze` must pass with zero issues; lint-suppression comments are forbidden (MEMORY, Feature 010).
  - `TextEditingController` must be disposed (`dispose_controllers`/`dispose_fields` lint + leak hygiene).
- **Theme**: use the global Material 3 theme; no explicit colors/shape/elevation at the call site (MEMORY, Feature 005: "Flutter built-in widgets deliver M3 theming for free").
- **Icons**: use `LucideIcons.save` from `lucide_icons_flutter` (fallback `Icons.save_outlined` only if `save` does not compile); do not add an icon package.
- **Localization**: keys in all three locales, `@`-metadata only in `app_en.arb`, consumed via `context.l10n`; regenerate with `flutter gen-l10n` (never hand-edit `app_localizations*.dart`).
- **No new dependencies**: `pubspec.yaml` is not modified.
- **Test framework**: `flutter_test` (+ `mocktail` if needed) per project convention; no new test deps.

## 8. Open Questions

- **DE/UK wording** (minor): UK values come directly from the HTML design (`Назва ліків`, `Зберегти`); DE values (`Medikamentenname`, `Speichern`) are standard translations. The user is the translator and may adjust either in a follow-up without changing the spec's structure.
- **`LucideIcons.save` name** (minor): not in MEMORY's verified-name list. If it fails to compile, AC-4 sanctions `Icons.save_outlined` as the fallback; resolve at execution time, no spec change needed.
- **Save-button placement** (minor): specced inline below the field inside the scroll view (matching the HTML's in-content `.btn-filled`). A pinned-footer layout (button anchored to the bottom of the screen) is a deferred styling choice; not adopted now to keep the iteration minimal.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Existing `body is empty` test breaks when the field/button are added | High | Low | The test update is bundled into the same task as the widget change (AC-10) so breakage is internal to one task. |
| A no-op Save button reads as "broken" to a future reader or reviewer | Med | Low | Document the no-op inline with a reference to this spec and the iteration roadmap; AC-5 makes the intent explicit and testable. |
| `LucideIcons.save` does not exist under that name | Low | Low | AC-4 fallback to `Icons.save_outlined`; verified at execution via `dart analyze`. |
| Keyboard overlaps the field/button on small screens | Low | Low | Body is a `SingleChildScrollView`, so the field scrolls above the keyboard instead of overflowing (AC-2). |
| `TextEditingController` leak if not disposed | Low | Med | AC-1 requires disposal in `dispose()`; the lint rule + code review cover it. |
| Future iterations copy-paste the no-op Save as a template and ship a dead button | Med | Med | Inline comment marks it as iteration-1 placeholder superseded by the data-save iteration; the iteration roadmap is recorded in `research/2026-06-11-add-medication-name-save.md`. |
