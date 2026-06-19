# Task 003: Fuzzy + ranked search in the meds-list view model

**Agent**: architect
**Files**: `lib/features/meds/presentation/view_models/meds_list_view_model.dart`
**Depends on**: 001
**Blocks**: 004, 006
**Context docs**: None
**Review checkpoint**: No

**Description**:
Replace the substring filter in `buildMedsListView` with the fuzzy scorer, keep the substring guarantee, and order results by descending match score while a query is active (alphabetical otherwise). Pure shaping logic — signature and `totalCount` semantics unchanged. Search still runs **before** the All/Active filter.

**Change details**:
- In `lib/features/meds/presentation/view_models/meds_list_view_model.dart`:
  - Import `package:dosly/core/utils/fuzzy_name_match.dart`.
  - Step 3 (search): when `query.trim()` is non-empty, **keep** an item if its name contains the query (case-insensitive substring — preserves today's behaviour) **OR** `fuzzyNameScore(query, name) >= kIncludeThreshold`. Define `kIncludeThreshold` as a named `const double` (≈ `0.6`, tunable; no magic number) with a dartdoc noting it's tuned against the debug seed set (OQ-2). Compute and retain each kept item's score (e.g. a local `List<(double score, MedListItem item)>`); blank query → all items, no scoring.
  - Step 5 (group + sort): after grouping into `continuous`/`course`, when the query is active sort each group by **descending score**, ties broken by `_byNameCaseInsensitive`; when the query is blank sort by `_byNameCaseInsensitive` (current behaviour). Do **not** add a score field to `MedListItem` — keep the score transient to the shaping pipeline.
  - Leave `MedsListView` (incl. `totalCount` = pre-filter input length), `MedsFilter`, derivation (activity/`CourseProgress`), and the `buildMedsListView` parameter list unchanged.

**Status**: Complete

**Done when**:
- [x] `buildMedsListView` uses `fuzzyNameScore`; a one-char-typo query (e.g. `'omeprzol'`) keeps the matching medication; an unrelated query drops it.
- [x] A pure substring/prefix query still matches (no regression) and ranks at/above fuzzy-only matches.
- [x] With an active query, each section is ordered by descending score (ties alphabetical); with a blank query, alphabetical.
- [x] `MedListItem` gains no new field; `buildMedsListView` signature and `MedsListView.totalCount` unchanged.
- [x] `dart analyze` passes (no magic numbers — threshold is a named const).

## Completion Notes
**Completed**: 2026-06-18
**Files changed**: `lib/features/meds/presentation/view_models/meds_list_view_model.dart`
**Contract**: Expects [2/2 verified] | Produces [4/4 verified]
**Notes**: Inclusion implemented as `fuzzyNameScore(query, name) >= medsSearchIncludeThreshold` (0.6) — subsumes the substring guarantee since substring/prefix always scores ≥0.9. Score carried transiently as `(double, MedListItem)` records through filter+group; emitted as plain `MedListItem`s (no model field). Sort switches on `hasQuery`: `_byScoreThenName` (desc score, ties name-asc) vs name-only. **Deviation (improvement)**: const named `medsSearchIncludeThreshold` (lowerCamelCase) not `kMeds…` — matches constitution §3.3 (constants are lowerCamelCase; `k` prefix reserved for private). All 12 existing VM tests still pass.

## Contracts

### Expects
- `lib/core/utils/fuzzy_name_match.dart` declares `double fuzzyNameScore(` (Task 001).
- `buildMedsListView({required List<Medication> meds, required DateTime now, required MedsFilter filter, required String query})` currently filters with a substring `.contains`.

### Produces
- `meds_list_view_model.dart` imports `fuzzy_name_match.dart` and references `fuzzyNameScore`.
- A named `const double kIncludeThreshold` (or equivalently-named const) exists in the file.
- `buildMedsListView` retains its existing parameter list and returns `MedsListView` with `totalCount` = input length; `MedListItem` has no `score`/`matchScore` field.
- When `query` is non-blank, `continuous` and `course` are ordered by descending match score; when blank, by case-insensitive name.

**Spec criteria addressed**: AC-5, AC-6, AC-7, AC-8
