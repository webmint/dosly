# Task 002: Unit-test the fuzzy name scorer

**Agent**: qa-engineer
**Files**: `test/core/utils/fuzzy_name_match_test.dart` (new)
**Depends on**: 001
**Blocks**: None
**Context docs**: None
**Review checkpoint**: No

**Description**:
Unit-test the pure scorer with fixed inputs across the cases the spec calls out (AC-9). No Flutter binding needed (pure Dart test). Use medication-name examples from the design/seed set so thresholds are validated against realistic data.

**Change details**:
- Create `test/core/utils/fuzzy_name_match_test.dart`:
  - `group('levenshtein', ...)`: identical strings → 0; one insertion/deletion/substitution → 1; transposition (`'ab'`↔`'ba'`) → 2 (classic Levenshtein); empty vs N → N.
  - `group('fuzzyNameScore', ...)`:
    - **Exact** match → `1.0` (or ≥ 0.99).
    - **Prefix** (`'ome'` → `'Omeprazol'`) → high score (near 1.0) and **strictly greater** than a one-typo non-substring score.
    - **Substring mid** (`'praz'` → `'Omeprazol'`) → high score, above fuzzy-only.
    - **One-char typo** (`'omeprzol'` → `'Omeprazol'`) → high-ish score (e.g. ≥ ~0.85) and above the include threshold the view model will use.
    - **Transliteration typo** (`'magnij b6'` → `'Magniy B6'`) → above threshold.
    - **Below-threshold non-match** (`'aspirin'` → `'Omeprazol'`) → low score (well below ~0.6).
    - **Case-insensitive Cyrillic** (`'мексиприм'` ↔ `'Мексиприм'`) → treated as exact/high (Unicode lower-casing works).
    - **Blank query** (`''`/`'   '`) → `0.0`.
- Assert relative ordering where the spec relies on it (substring > fuzzy-only) rather than only absolute thresholds, so the test survives minor constant tuning.

**Status**: Complete

**Done when**:
- [x] `test/core/utils/fuzzy_name_match_test.dart` covers: exact, prefix, mid-substring, one-char typo, transliteration typo, below-threshold non-match, Cyrillic case-fold, blank query.
- [x] `flutter test test/core/utils/fuzzy_name_match_test.dart` passes.
- [x] `dart analyze` passes on the test file.

## Completion Notes
**Completed**: 2026-06-18
**Files changed**: `test/core/utils/fuzzy_name_match_test.dart` (new)
**Contract**: Expects [1/1 verified] | Produces [2/2 verified]
**Notes**: 38 cases (10 levenshtein + 28 fuzzyNameScore across blank/exact/prefix/mid/fuzzy-typo/invariant/edge groups). Assertions use relative ordering (`greaterThan`/`lessThan`/`closeTo`) so they survive constant tuning. Documented that `levenshtein` is case-sensitive by design (`fuzzyNameScore` lowercases first). No production code touched; no scorer bug found.

## Contracts

### Expects
- `lib/core/utils/fuzzy_name_match.dart` declares `fuzzyNameScore` and `levenshtein` (Task 001).

### Produces
- `test/core/utils/fuzzy_name_match_test.dart` exists with `group('fuzzyNameScore'` asserting the substring-outranks-fuzzy and typo-above-threshold relationships.
- The test suite passes under `flutter test`.

**Spec criteria addressed**: AC-9
