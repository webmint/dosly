# Task 001: Add intake-type & course l10n keys (en/uk/de)

**Agent**: mobile-engineer
**Review checkpoint**: No
**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_uk.arb`, `lib/l10n/app_de.arb` (+ regenerated `lib/l10n/app_localizations*.dart`)
**Depends on**: None
**Blocks**: 002
**Context docs**: None

**Description**:
Add the nine new `medsAdd*` localization keys the intake-type section needs, to all three arb files, then regenerate the localizations. This introduces the project's **first** placeholder and **first ICU-plural** message, so the `@`-metadata in the template (`app_en.arb`) must be authored precisely. Without this task the widget in Task 002 will not compile (its `context.l10n.medsAdd*` references won't exist).

**Change details**:
- In `lib/l10n/app_en.arb` (the gen-l10n **template** — `@`-metadata lives here only):
  - Add the 9 keys below. For `medsAddCourseRangeLabel` and `medsAddCourseStartOnly`, add `@`-metadata declaring placeholders (`range`: String, `count`: int; `date`: String). The other 7 keys are plain strings; give each a short `@`-description matching the style of existing keys.
- In `lib/l10n/app_uk.arb` and `lib/l10n/app_de.arb`:
  - Add the same 9 keys with translations (no `@`-metadata — that belongs only in the template).
  - The plural message must use the locale's CLDR categories: **uk** needs `one`/`few`/`many`/`other`; **de** uses `=1`/`other`.
- Regenerate: run `flutter gen-l10n` so `lib/l10n/app_localizations*.dart` exposes the new getters/methods before Task 002 compiles.

**Reference values** (verify/refine translations; keep the placeholder/plural structure exactly):

| Key | en | uk | de |
|-----|----|----|----|
| `medsAddIntakeTypeTitle` | `Intake type` | `Тип прийому` | `Einnahmeart` |
| `medsAddIntakeTypeContinuous` | `Continuous` | `Постійний` | `Dauerhaft` |
| `medsAddIntakeTypeCourse` | `Course` | `Курс` | `Kur` |
| `medsAddCourseParamsTitle` | `Course parameters` | `Параметри курсу` | `Kurparameter` |
| `medsAddCourseDurationLabel` | `Duration (days)` | `Тривалість (дні)` | `Dauer (Tage)` |
| `medsAddCoursePauseLabel` | `Pause (days)` | `Пауза (дні)` | `Pause (Tage)` |
| `medsAddCourseStartLabel` | `Start date` | `Дата початку` | `Startdatum` |
| `medsAddCourseRangeLabel` | `Course: {range} ({count, plural, =1{1 day} other{{count} days}})` | `Курс: {range} ({count, plural, one{{count} день} few{{count} дні} many{{count} днів} other{{count} дня}})` | `Kur: {range} ({count, plural, =1{1 Tag} other{{count} Tage}})` |
| `medsAddCourseStartOnly` | `Course starts {date}` | `Курс починається {date}` | `Kur beginnt {date}` |

Template `@`-metadata to add to `app_en.arb`:
```json
"@medsAddCourseRangeLabel": {
  "description": "Course info chip: localized date range plus a pluralized day count.",
  "placeholders": { "range": { "type": "String" }, "count": { "type": "int" } }
},
"@medsAddCourseStartOnly": {
  "description": "Course info-chip fallback shown when the duration is empty or not a positive integer.",
  "placeholders": { "date": { "type": "String" } }
}
```

**Status**: Complete

**Done when**:
- [x] All 9 keys exist in `app_en.arb`, `app_uk.arb`, and `app_de.arb`.
- [x] `app_en.arb` declares `@medsAddCourseRangeLabel` (placeholders `range`:String, `count`:int) and `@medsAddCourseStartOnly` (placeholder `date`:String).
- [x] `medsAddCourseRangeLabel` uses an ICU `{count, plural, …}` block in every locale; uk includes `one`/`few`/`many`/`other`.
- [x] `flutter gen-l10n` runs without error; `app_localizations.dart` exposes `String medsAddCourseRangeLabel(String range, int count)`, `String medsAddCourseStartOnly(String date)`, and `String get medsAddIntakeTypeTitle` (+ the other plain getters).
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-9 (plural string), AC-10 (fallback string), AC-11 (3 locales, uk plural)

## Contracts

### Expects
- `lib/l10n/app_en.arb` exists and is the gen-l10n template per `l10n.yaml` (`template-arb-file: app_en.arb`, `output-class: AppLocalizations`).
- `app_uk.arb` and `app_de.arb` exist and currently hold the ~78 existing `medsAdd*` keys.
- `pubspec.yaml` has `flutter: generate: true` (synthetic localizations generation enabled).

### Produces
- `app_en.arb`, `app_uk.arb`, `app_de.arb` each contain the literal keys `medsAddIntakeTypeTitle`, `medsAddIntakeTypeContinuous`, `medsAddIntakeTypeCourse`, `medsAddCourseParamsTitle`, `medsAddCourseDurationLabel`, `medsAddCoursePauseLabel`, `medsAddCourseStartLabel`, `medsAddCourseRangeLabel`, `medsAddCourseStartOnly`.
- `app_en.arb` contains `"@medsAddCourseRangeLabel"` with a `"placeholders"` object naming `range` and `count`.
- Generated `AppLocalizations` declares method `medsAddCourseRangeLabel(String range, int count)` and method `medsAddCourseStartOnly(String date)`.
- Generated `AppLocalizations` declares getter `medsAddIntakeTypeContinuous` and `medsAddIntakeTypeCourse`.

## Completion Notes

**Completed**: 2026-06-15
**Files changed**: lib/l10n/app_en.arb, app_uk.arb, app_de.arb (+ regenerated app_localizations.dart, _en, _uk, _de)
**Contract**: Expects [3/3 verified] | Produces [4/4 verified — 9 keys ×3 arbs, @-metadata placeholders, generated `medsAddCourseRangeLabel(String,int)` + `medsAddCourseStartOnly(String)`, plain getters]
**Verification**: dart analyze clean; flutter test 313/313 pass; flutter gen-l10n OK.
**Code review**: APPROVE WITH WARNINGS — uk `other`=`{count} дня` is CLDR-valid (only reached for fractional counts; integer day-counts dispatch via one/few/many); mixed `=1` (en/de) vs `one` (uk) ICU style is legal. No Critical. No fix required.
**Notes**: First ICU-plural + first placeholder metadata in the project. Keys inserted after `medsAddTimeDuplicate`. de "Kur" chosen for "Course" (medical term) — content-owner may revisit.
