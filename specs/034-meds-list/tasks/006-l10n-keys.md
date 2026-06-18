# Task 006: List-screen l10n keys (en/de/uk)

**Agent**: mobile-engineer
**Files**: `lib/l10n/app_en.arb` (modify), `lib/l10n/app_de.arb` (modify), `lib/l10n/app_uk.arb` (modify)
**Depends on**: None
**Blocks**: 008, 010, 011
**Context docs**: `specs/034-meds-list/data-model.md` (l10n key table)
**Review checkpoint**: No

**Description**:
Add every new user-facing string for the list screen to all three locale ARB files, with real translations (no English placeholders in de/uk). Ukrainian must match the design wording. Two keys are parameterized (`int` placeholders). Regenerate the localizations so the typed getters exist for downstream widget tasks.

**Change details**:
- Add the keys from `data-model.md` to `app_en.arb` (canonical, with `@key` metadata + `placeholders` for the parameterized ones), then mirror into `app_de.arb` and `app_uk.arb` with translations:
  - Plain: `medsListTitle`, `medsListSearchHint`, `medsListSearchTooltip`, `medsListFilterAll`, `medsListFilterActive`, `medsListSectionContinuous`, `medsListSectionCourse`, `medsListSectionEmpty`, `medsListEmptyTitle`, `medsListEmptyBody`, `medsListStatusActive`, `medsListStatusCompleted`, `medsListTypeContinuous`, `medsListTypeCoursePaused`.
  - Parameterized: `medsListTypeCourseDay` (`{current}`, `{total}` — `type: int`), `medsListStock` (`{remaining}`, `{total}` — `type: int`).
  - Dose-unit abbreviations: `doseUnitTablet`, `doseUnitCapsule`, `doseUnitMl`, `doseUnitMg`, `doseUnitDrops`, `doseUnitUnits`, `doseUnitPuff`, `doseUnitApplication`, `doseUnitSachet`.
- uk values per the design (e.g. `medsListTitle` = "Мої ліки", `medsListSectionContinuous` = "Постійні", `medsListSectionCourse` = "Курсові", `medsListSectionEmpty` = "Нічого не знайдено", `medsListTypeCourseDay` = "День {current}/{total}", `medsListStock` = "{remaining} з {total} шт", `doseUnitUnits` = "МО").
- Run `flutter gen-l10n` (or `flutter pub get` if wired to build); ensure `app_localizations*.dart` regenerate with the new getters.

**Done when**:
- [x] All keys present in all three ARB files with translations; parameterized keys declare `int` placeholders.
- [x] `flutter gen-l10n` succeeds; `context.l10n.medsListTitle` etc. resolve (generated getters exist).
- [x] `dart analyze` clean (no missing-translation warnings).

**Spec criteria addressed**: AC-15

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: app_en.arb (+@metadata), app_de.arb, app_uk.arb (+ generated app_localizations*.dart)
**Contract**: Expects 1/1 verified | Produces 2/2 verified
**Notes**: 25 keys ×3 locales. uk matches design ("Мої ліки", "Постійні", "Курсові", "День {current}/{total}", "{remaining} з {total} шт"). de/uk are value-only (no `@` metadata) per existing convention. Parameterized getters: `medsListTypeCourseDay(int current, int total)`, `medsListStock(int remaining, int total)`. gen-l10n clean.

## Contracts

### Expects
- `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` exist and are the maintained locales; `flutter gen-l10n` is configured.

### Produces
- `app_en.arb` (and de/uk) contain the keys `medsListTitle` … `doseUnitSachet` listed above; `medsListTypeCourseDay` and `medsListStock` declare `placeholders` of `type: int`.
- Generated `AppLocalizations` exposes getters `medsListTitle`, `medsListTypeCourseDay(int current, int total)`, `medsListStock(int remaining, int total)`, and the `doseUnit*` getters.
