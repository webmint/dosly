# Task 004: Test fuzzy inclusion + ranking in the view model

**Agent**: qa-engineer
**Files**: `test/features/meds/presentation/view_models/meds_list_view_model_test.dart`
**Depends on**: 003
**Blocks**: None
**Context docs**: None
**Review checkpoint**: No

**Description**:
Extend the existing view-model test to cover the new fuzzy + ranking behaviour without regressing the existing grouping/filter/derivation assertions. Use `withClock(Clock.fixed(...))` for any activity-dependent fixtures (per MEMORY — never `DateTime.now()`); build fixtures with explicit dates.

**Change details**:
- In `test/features/meds/presentation/view_models/meds_list_view_model_test.dart`, add a `group('search', ...)` (or extend the existing one):
  - **Typo inclusion**: a one-char-typo query keeps the intended medication (e.g. `'omeprzol'` keeps "Omeprazol").
  - **Substring guarantee**: a substring/prefix query still matches (`'ome'` keeps "Omeprazol"); assert no regression vs prior behaviour.
  - **Exclusion**: an unrelated query (e.g. `'xyz'`) yields empty `continuous` + `course`.
  - **Score ranking under query**: given two meds in the same section where one is a closer match, assert the closer match is ordered first (substring/exact ahead of a fuzzy-only match).
  - **Alphabetical without query**: blank query → existing case-insensitive name ordering preserved.
  - **Filter after search**: with `MedsFilter.active` + a query that matches a completed course, the completed item is excluded by the filter (search→filter order intact).
  - **`totalCount`**: unchanged = pre-filter input length even when search narrows results.
- Keep existing tests green; only add/adjust.

**Status**: Complete

**Done when**:
- [x] New cases: typo inclusion, substring guarantee, exclusion, score ranking, alphabetical-without-query, filter-after-search, totalCount-unchanged.
- [x] `flutter test test/features/meds/presentation/view_models/meds_list_view_model_test.dart` passes (existing + new).
- [x] `dart analyze` passes on the test file.

## Completion Notes
**Completed**: 2026-06-18
**Files changed**: `test/features/meds/presentation/view_models/meds_list_view_model_test.dart`
**Contract**: Expects [1/1 verified] | Produces [2/2 verified]
**Notes**: 19 tests total (7 new). Score-over-alphabetical proven with "Avitamin Complex" (contains, 0.90) vs "Vitamin D" (prefix, 0.95) under query `'vitamin'` — "Vitamin D" lands at index 0 despite sorting later alphabetically. Filter-after-search uses a Clock-fixed `now` (2026-06-18) past a course's derived end so it is Completed and excluded by `MedsFilter.active`. No production change; no bug found.

## Contracts

### Expects
- `buildMedsListView` uses `fuzzyNameScore`, orders by score under an active query and by name when blank, and keeps `totalCount` = input length (Task 003).

### Produces
- `meds_list_view_model_test.dart` contains assertions for fuzzy typo inclusion, substring guarantee, score-ranked ordering, and alphabetical ordering without a query.
- The suite passes under `flutter test`.

**Spec criteria addressed**: AC-6, AC-7, AC-8
