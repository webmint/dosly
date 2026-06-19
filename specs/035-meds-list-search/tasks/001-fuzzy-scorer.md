# Task 001: Create pure-Dart fuzzy name scorer

**Agent**: architect
**Files**: `lib/core/utils/fuzzy_name_match.dart` (new)
**Depends on**: None
**Blocks**: 002, 003
**Context docs**: None
**Review checkpoint**: No

**Description**:
Create a generic, dependency-free fuzzy string matcher in `core/utils` (no package, per `plan.md` / `research.md`). It exposes a normalized 0..1 similarity used by the meds-list view model to include + rank medications by name with typo tolerance. Pure Dart only — no Flutter, no drift, no wall-clock. Generic and feature-agnostic (reusable for future searchable lists), so it lives in `lib/core/utils/`, not in the meds feature.

**Change details**:
- Create `lib/core/utils/fuzzy_name_match.dart`:
  - `int levenshtein(String a, String b)` — classic edit distance (insert/delete/substitute), computed over **characters** (use `String.toLowerCase()` first by the caller, or normalize inside; iterate `runes`/`characters` so Cyrillic + Latin BMP names count correctly). Two-row DP, no `!`, typed.
  - `double fuzzyNameScore(String query, String name)` — returns a similarity in `[0.0, 1.0]`:
    - Case-insensitive (`toLowerCase()` both; trim the query).
    - **Substring/prefix bonus**: if `name` starts with `query` → score near `1.0`; else if `name` contains `query` → a high score strictly **above** any fuzzy-only match (e.g. ≥ 0.9). This guarantees substring matches always rank first and always pass any reasonable threshold (spec AC-6).
    - **Fuzzy fallback**: otherwise `1 - levenshtein(query, name) / maxLen` (where `maxLen = max(query.length, name.length)`), clamped to `[0,1]`.
    - Empty/whitespace query → return `0.0` (callers treat blank query as "no search", so the score is unused, but keep it total).
  - Dartdoc every public member; named params where >1 arg; `final`/`const` per lints.
- Do **not** add any dependency to `pubspec.yaml`.

**Status**: Complete

**Done when**:
- [x] `lib/core/utils/fuzzy_name_match.dart` exists with public `fuzzyNameScore` and `levenshtein`.
- [x] No `package:flutter`, `package:drift`, or `DateTime` use in the file (pure Dart).
- [x] `dart analyze` passes on the new file (no `dynamic`, no `!`, no unchecked `as`).
- [x] No new entry added to `pubspec.yaml`.

## Completion Notes
**Completed**: 2026-06-18
**Files changed**: `lib/core/utils/fuzzy_name_match.dart` (new)
**Contract**: Expects [2/2 verified] | Produces [3/3 verified]
**Notes**: Score bands are named consts — exact `1.0` ≥ prefix `0.95` > contains `0.9` > fuzzy clamped to `[0, 0.85]`. The `_maxFuzzyScore (0.85) < _containsScore (0.9)` invariant is what guarantees substring/prefix always outranks a typo'd fuzzy-only match (AC-6). Levenshtein is two-row DP over `runes` (Cyrillic-safe). `dart analyze` clean; no dependency added.

## Contracts

### Expects
- `lib/core/` exists and the project imports via `package:dosly/...`.
- No existing fuzzy/search utility in `lib/core/utils/` (greenfield file).

### Produces
- `lib/core/utils/fuzzy_name_match.dart` declares top-level `double fuzzyNameScore(` and `int levenshtein(`.
- `fuzzyNameScore` returns a value in `[0.0, 1.0]`; a case-insensitive substring/prefix match scores strictly higher than a non-substring fuzzy match; an empty/whitespace query scores `0.0`.
- The file imports nothing from `package:flutter`, `package:drift`, or uses `DateTime.now()`.

**Spec criteria addressed**: AC-5, AC-6
