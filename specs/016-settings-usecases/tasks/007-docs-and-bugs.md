# Task 007: Update docs + close bugs 005 and 011

**Agent**: tech-writer
**Files**:
- `docs/features/settings.md` (modify)
- `bugs/005-settings-feature-missing-usecases.md` (modify)
- `bugs/011-business-rule-duplicated-selectors.md` (modify)

**Depends on**: 006
**Blocks**: None
**Context docs**: `docs/features/settings.md`, `bugs/005-settings-feature-missing-usecases.md`, `bugs/011-business-rule-duplicated-selectors.md`
**Review checkpoint**: No

## Description

Mechanical post-implementation bookkeeping. Three pure-markdown edits:

1. Update `docs/features/settings.md` to describe the new use case layer, the `AppLanguage.fromLanguageCodeOrDefault` helper, and the simplified widget callbacks. Reflect the implementation reality after Task 006 ships.
2. Flip `bugs/005-...md` and `bugs/011-...md` from `Status: Open` to `Status: Closed` and set the `Fixed:` field to `2026-05-10`.

This task does not touch any source code and does not run the integration gate (already proven by Task 006).

## Change details

- In `docs/features/settings.md`:
  - **"How it works → Domain" subsection**: Add a "Use cases" paragraph or sub-subsection between "Presentation seam" and "Data". List the five use cases with one-line summaries:
    - `SetThemeMode` — persists the manual `AppThemeMode`.
    - `SetUseSystemTheme` — atomic toggle: when turning the system flag OFF, pre-fills the manual mode with the resolved device brightness in the same logical operation.
    - `SetManualLanguage` — persists the manual `AppLanguage`.
    - `SetUseSystemLanguage` — atomic toggle symmetric to `SetUseSystemTheme` with `AppLanguage`.
    - `CycleThemeMode` — encodes the `system → light → dark → system` cycle for the dev-only `theme_preview_screen.dart` button. Returns the resulting `(useSystemTheme, manualThemeMode)` record on Right.
  - **"How it works → Presentation" subsection**: Update the `setUseSystemTheme` example to show the new signature with `currentDeviceMode`. Note that all four mutators delegate through use case providers; mention `cycleThemeMode()` as a fifth public method.
  - **"ThemeSelector widget" section**: Remove the existing pre-fill code block (the `if (!value)` flow). Replace with a one-line description: "On any toggle change, the widget computes the device-resolved `AppThemeMode` from `MediaQuery.platformBrightnessOf` and forwards it to `setUseSystemTheme(value, currentDeviceMode: deviceMode)`. The pre-fill rule lives in `SetUseSystemTheme` — see the use case section."
  - **"LanguageSelector widget" section**: Same treatment. Reference `AppLanguage.fromLanguageCodeOrDefault` for the device-code resolution. Remove the `firstWhere(orElse: en)` code block in favor of a one-line note pointing at the helper.
  - **"Related" section**: Add a link to `../../specs/016-settings-usecases/spec.md`.

- In `bugs/005-settings-feature-missing-usecases.md`:
  - Change `**Status**: Open` to `**Status**: Closed`.
  - Change `**Fixed**:` to `**Fixed**: 2026-05-10`.

- In `bugs/011-business-rule-duplicated-selectors.md`:
  - Same two flips.

## Done when

- [x] `docs/features/settings.md` has a "Use cases" subsection enumerating the five use cases.
- [x] `docs/features/settings.md` no longer contains the pre-fill code blocks under ThemeSelector / LanguageSelector — those subsections describe the simplified one-call callback and reference the use cases as the rule's home.
- [x] `docs/features/settings.md`'s Related section links spec 016.
- [x] `bugs/005-...md` shows `Status: Closed` and `Fixed: 2026-05-10`.
- [x] `bugs/011-...md` shows `Status: Closed` and `Fixed: 2026-05-10`.
- [x] `dart analyze` (no source changes — sanity check; no-op).
- [x] No source files modified outside `docs/` and `bugs/`.

## Spec criteria addressed

AC-19, AC-20.

## Completion Notes

**Status**: Complete
**Completed**: 2026-05-10
**Files changed**:
- `docs/features/settings.md` — added Use cases subsection (5 use cases tabled), rewrote Presentation example to new signature, replaced ThemeSelector / LanguageSelector pre-fill code blocks with prose descriptions, added spec 016 link in Related
- `bugs/005-settings-feature-missing-usecases.md` — Status: Open → Closed, Fixed: 2026-05-10
- `bugs/011-business-rule-duplicated-selectors.md` — same flips
- `specs/016-settings-usecases/spec.md` — AC-19 + Affected Areas date corrected from 2026-05-09 to 2026-05-10 (work spread one day from authorship)

**Contract**: Expects 3/3 verified | Produces 4/4 verified

**Notes**:
- Code review: REQUEST CHANGES → APPROVE on re-review (after date alignment).
- The first review flagged a date drift between the bugs (2026-05-10, real) and the task spec's prescription (2026-05-09, drafted yesterday). Resolution: aligned spec + task forward to 2026-05-10 to match the actual fix-landing date. Bugs left at 2026-05-10. The spec's authorship header date and the research link date are preserved as historical markers.
- No source code touched. Integration gate from Task 006 still green.

## Contracts

### Expects
- All Task 006 changes are merged: simplified callbacks, helper-based `AppLanguage` resolution, cycle delegation.
- `bugs/005-settings-feature-missing-usecases.md` and `bugs/011-business-rule-duplicated-selectors.md` exist and currently show `Status: Open`.
- `docs/features/settings.md` exists and currently describes the pre-implementation widget pre-fill flow.

### Produces
- `docs/features/settings.md` reflects the post-spec-016 implementation: a "Use cases" subsection, simplified ThemeSelector/LanguageSelector subsections without pre-fill code blocks, and a spec-016 link in Related.
- Both bug files show `Status: Closed` and `Fixed: 2026-05-10`.
