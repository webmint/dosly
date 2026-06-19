/// Generic, dependency-free fuzzy string matching for searchable name lists.
///
/// Exposes [levenshtein] (classic edit distance) and [fuzzyNameScore] (a
/// normalized `0.0..1.0` similarity built on top of it). The score is used by
/// searchable list view models — initially the meds list — to both include and
/// rank items by name with typo tolerance, while still guaranteeing that plain
/// substring matches always win over fuzzy-only matches.
///
/// Pure Dart: no Flutter, no drift, no wall-clock ([DateTime]). The only import
/// is `dart:math`. Because it is feature-agnostic it lives in `core/utils/`
/// rather than inside any feature module, and is safe to unit-test without
/// pumping widgets or freezing time.
///
/// ## Score bands (highest to lowest)
///
/// [fuzzyNameScore] returns one of four disjoint bands so ordering is total and
/// predictable:
///
/// * `1.0` — exact match (query equals name after lowercase + trim).
/// * `~0.95` ([_prefixScore]) — name starts with the query but is not equal.
/// * `~0.9` ([_containsScore]) — name contains the query elsewhere (not a
///   prefix). Strictly above every value the fuzzy fallback can produce.
/// * `[0.0, _maxFuzzyScore]` — no substring match; falls back to
///   `1 - editDistance / maxLength`, capped strictly below [_containsScore].
///
/// The invariant `1.0 >= prefix > contains > anyFuzzyOnlyScore` means a
/// case-insensitive substring match always ranks above (and any reasonable
/// threshold passes before) a fuzzy-only match.
library;

import 'dart:math';

/// Score returned when [name] starts with the query but is not equal to it.
///
/// Sits just below `1.0` (the exact-match score) and above [_containsScore],
/// so a prefix match outranks a mid-string substring match.
const double _prefixScore = 0.95;

/// Score returned when [name] contains the query as a non-prefix substring.
///
/// Chosen strictly greater than [_maxFuzzyScore] so any substring match always
/// outranks any fuzzy-only (non-substring) match.
const double _containsScore = 0.9;

/// Upper bound clamped onto the fuzzy fallback (non-substring) score.
///
/// Kept strictly below [_containsScore] to preserve the band ordering: a
/// fuzzy-only match can never reach or exceed a substring match's score.
const double _maxFuzzyScore = 0.85;

/// Computes the Levenshtein edit distance between [a] and [b].
///
/// The edit distance is the minimum number of single-character insertions,
/// deletions, or substitutions (each cost 1) required to transform [a] into
/// [b]. Distance is `0` iff the strings are identical.
///
/// Comparison is per Unicode code point (via [String.runes]), so Cyrillic and
/// Latin BMP characters each count as a single unit. Uses the two-row dynamic
/// programming formulation: O(`a.length` x `b.length`) time and O(min length)
/// extra space.
///
/// Pure Dart; no side effects.
int levenshtein(String a, String b) {
  final List<int> sourceRunes = a.runes.toList(growable: false);
  final List<int> targetRunes = b.runes.toList(growable: false);

  if (sourceRunes.isEmpty) {
    return targetRunes.length;
  }
  if (targetRunes.isEmpty) {
    return sourceRunes.length;
  }

  // Index the shorter sequence along the rows to keep the row buffers small
  // (O(min) space). The distance is symmetric, so swapping is harmless.
  final List<int> shorter = sourceRunes.length <= targetRunes.length
      ? sourceRunes
      : targetRunes;
  final List<int> longer = sourceRunes.length <= targetRunes.length
      ? targetRunes
      : sourceRunes;

  // previousRow[i] = distance between longer[0..currentLongerIndex-1] and
  // shorter[0..i]. Initialized for an empty `longer` prefix: i deletions.
  List<int> previousRow = List<int>.generate(
    shorter.length + 1,
    (int i) => i,
    growable: false,
  );

  for (int j = 1; j <= longer.length; j++) {
    final List<int> currentRow = List<int>.filled(shorter.length + 1, 0);
    // Distance from longer[0..j-1] to an empty `shorter` prefix: j insertions.
    currentRow[0] = j;

    for (int i = 1; i <= shorter.length; i++) {
      final int substitutionCost = shorter[i - 1] == longer[j - 1] ? 0 : 1;
      final int deletion = previousRow[i] + 1;
      final int insertion = currentRow[i - 1] + 1;
      final int substitution = previousRow[i - 1] + substitutionCost;
      currentRow[i] = min(substitution, min(deletion, insertion));
    }

    previousRow = currentRow;
  }

  return previousRow[shorter.length];
}

/// Scores how well [name] matches [query] as a similarity in `[0.0, 1.0]`.
///
/// Both arguments are lowercased ([String.toLowerCase], which is Unicode-aware,
/// so Cyrillic case folds correctly) and [query] is trimmed before comparison.
/// Higher means more similar. The result falls into one of four disjoint bands
/// (see the library doc) so ranking is total and substring matches always win:
///
/// * Empty/whitespace-only [query] -> `0.0`.
/// * Exact match (`query == name` after normalization) -> `1.0`.
/// * [name] starts with [query] (non-exact) -> [_prefixScore] (`~0.95`).
/// * [name] contains [query] elsewhere -> [_containsScore] (`~0.9`).
/// * Otherwise (no substring) -> `1 - levenshtein(query, name) / maxLength`,
///   clamped to `[0.0, _maxFuzzyScore]`, where `maxLength` is the longer of the
///   two lengths. This fuzzy-only band is strictly below [_containsScore], so a
///   typo'd query can never outrank a true substring match.
///
/// Pure Dart; no side effects.
double fuzzyNameScore(String query, String name) {
  final String normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return 0.0;
  }

  final String normalizedName = name.toLowerCase();

  if (normalizedQuery == normalizedName) {
    return 1.0;
  }
  if (normalizedName.startsWith(normalizedQuery)) {
    return _prefixScore;
  }
  if (normalizedName.contains(normalizedQuery)) {
    return _containsScore;
  }

  // Fuzzy fallback: similarity = 1 - normalizedEditDistance.
  final int queryLength = normalizedQuery.runes.length;
  final int nameLength = normalizedName.runes.length;
  final int maxLength = max(queryLength, nameLength);
  if (maxLength == 0) {
    return 0.0;
  }

  final int distance = levenshtein(normalizedQuery, normalizedName);
  final double similarity = 1.0 - distance / maxLength;
  return similarity.clamp(0.0, _maxFuzzyScore);
}
