// Tests for [levenshtein] and [fuzzyNameScore] in
// `lib/core/utils/fuzzy_name_match.dart`.
//
// Pure-Dart: no Flutter binding, no widget pumping, no DB or clock.
//
// Assertion philosophy:
// - Exact-float equality is used only for integer-valued outputs (levenshtein)
//   and the two sentinel values 0.0 and 1.0 (blank query / exact match).
// - All other score assertions use relational matchers (greaterThan,
//   lessThan, closeTo) so minor constant-tuning does not break tests.
// - Relative ordering (substring > fuzzy-only) is always asserted via
//   `greaterThan` comparisons rather than checking absolute thresholds.

import 'package:dosly/core/utils/fuzzy_name_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // levenshtein
  // ---------------------------------------------------------------------------

  group('levenshtein', () {
    test('should return 0 for identical strings', () {
      expect(levenshtein('Omeprazol', 'Omeprazol'), equals(0));
    });

    test('should return 0 for two empty strings', () {
      expect(levenshtein('', ''), equals(0));
    });

    test('should return N for empty string vs N-char string', () {
      expect(levenshtein('', 'abc'), equals(3));
      expect(levenshtein('abc', ''), equals(3));
    });

    test('should return 1 for a single insertion', () {
      // 'cat' → 'cats' is one insertion.
      expect(levenshtein('cat', 'cats'), equals(1));
    });

    test('should return 1 for a single deletion', () {
      // 'cats' → 'cat' is one deletion.
      expect(levenshtein('cats', 'cat'), equals(1));
    });

    test('should return 1 for a single substitution', () {
      // 'cat' → 'bat' is one substitution.
      expect(levenshtein('cat', 'bat'), equals(1));
    });

    test('should return 2 for transposition of adjacent characters (ab vs ba)',
        () {
      // Classic Levenshtein treats transposition as two edits (delete + insert).
      expect(levenshtein('ab', 'ba'), equals(2));
    });

    test('should be symmetric', () {
      expect(
        levenshtein('omeprazol', 'omeprzol'),
        equals(levenshtein('omeprzol', 'omeprazol')),
      );
    });

    test('should return correct distance for a realistic one-typo medication name',
        () {
      // 'omeprzol' vs 'omeprazol' — one deleted 'a'.
      expect(levenshtein('omeprzol', 'omeprazol'), equals(1));
    });

    test('should handle Cyrillic strings correctly', () {
      // 'мексиприм' vs 'Мексиприм' — case folding is NOT done by levenshtein;
      // it operates on raw runes, so 'м' ≠ 'М' → distance 1.
      expect(levenshtein('мексиприм', 'Мексиприм'), equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // fuzzyNameScore
  // ---------------------------------------------------------------------------

  group('fuzzyNameScore', () {
    // -------------------------------------------------------------------------
    // Blank / empty query → 0.0
    // -------------------------------------------------------------------------

    group('blank query', () {
      test('should return 0.0 for an empty query string', () {
        expect(fuzzyNameScore('', 'Omeprazol'), equals(0.0));
      });

      test('should return 0.0 for a whitespace-only query string', () {
        expect(fuzzyNameScore('   ', 'Omeprazol'), equals(0.0));
      });

      test('should return 0.0 for a tab-only query string', () {
        expect(fuzzyNameScore('\t', 'Omeprazol'), equals(0.0));
      });
    });

    // -------------------------------------------------------------------------
    // Exact match → 1.0
    // -------------------------------------------------------------------------

    group('exact match', () {
      test('should return 1.0 for an exact case-sensitive match', () {
        expect(fuzzyNameScore('Omeprazol', 'Omeprazol'), equals(1.0));
      });

      test('should return 1.0 for an exact case-insensitive match (Latin)', () {
        expect(fuzzyNameScore('omeprazol', 'Omeprazol'), equals(1.0));
      });

      test('should return 1.0 for an exact case-insensitive match (multi-word)',
          () {
        expect(fuzzyNameScore('magniy b6', 'Magniy B6'), equals(1.0));
      });

      test(
          'should return 1.0 for an exact case-insensitive Cyrillic match (case fold)',
          () {
        // Unicode-aware toLowerCase folds Cyrillic correctly.
        expect(fuzzyNameScore('мексиприм', 'Мексиприм'),
            greaterThanOrEqualTo(0.99));
      });

      test('should return 1.0 for query with surrounding whitespace (trimmed)',
          () {
        expect(fuzzyNameScore('  Omeprazol  ', 'Omeprazol'), equals(1.0));
      });
    });

    // -------------------------------------------------------------------------
    // Prefix match → ~0.95
    // -------------------------------------------------------------------------

    group('prefix match', () {
      test(
          'should return ~0.95 for a prefix query that does not equal the full name',
          () {
        final double score = fuzzyNameScore('ome', 'Omeprazol');
        // Sits in the prefix band: [0.94, 0.96].
        expect(score, closeTo(0.95, 0.01));
      });

      test('should return ~0.95 for a prefix of a Cyrillic medication name',
          () {
        final double score = fuzzyNameScore('мекс', 'Мексиприм');
        expect(score, closeTo(0.95, 0.01));
      });

      test(
          'should return ~0.95 for a case-insensitive prefix of a multi-word name',
          () {
        final double score = fuzzyNameScore('magn', 'Magniy B6');
        expect(score, closeTo(0.95, 0.01));
      });

      test(
          'should rank prefix match strictly above a same-query fuzzy-only match',
          () {
        // 'ome' is a prefix of 'Omeprazol' (~0.95).
        // 'aspir' has no substring and no relation to 'Omeprazol' (fuzzy-only).
        final double prefixScore = fuzzyNameScore('ome', 'Omeprazol');
        final double fuzzyOnlyScore = fuzzyNameScore('aspir', 'Omeprazol');
        expect(prefixScore, greaterThan(fuzzyOnlyScore));
      });
    });

    // -------------------------------------------------------------------------
    // Mid-substring (contains) match → ~0.9
    // -------------------------------------------------------------------------

    group('mid-substring (contains) match', () {
      test(
          'should return ~0.9 for a substring that is not a prefix of the name',
          () {
        final double score = fuzzyNameScore('praz', 'Omeprazol');
        expect(score, closeTo(0.9, 0.01));
      });

      test('should return ~0.9 for a mid-substring of a Cyrillic name', () {
        final double score = fuzzyNameScore('ексип', 'Мексиприм');
        expect(score, closeTo(0.9, 0.01));
      });

      test('should rank prefix match strictly above mid-substring match', () {
        // Prefix is ~0.95, mid-substring is ~0.9 — expected ordering: prefix > contains.
        final double prefixScore = fuzzyNameScore('ome', 'Omeprazol');
        final double containsScore = fuzzyNameScore('praz', 'Omeprazol');
        expect(prefixScore, greaterThan(containsScore));
      });

      test(
          'should rank mid-substring match strictly above a non-substring fuzzy score',
          () {
        // 'praz' is a substring of 'Omeprazol' (~0.9).
        // 'zolpid' is not in 'Omeprazol' at all (fuzzy-only, will be < 0.85).
        final double containsScore = fuzzyNameScore('praz', 'Omeprazol');
        final double fuzzyOnlyScore = fuzzyNameScore('zolpid', 'Omeprazol');
        expect(containsScore, greaterThan(fuzzyOnlyScore));
      });
    });

    // -------------------------------------------------------------------------
    // Fuzzy-only (non-substring, typo) → clamped to [0, ~0.85]
    // -------------------------------------------------------------------------

    group('fuzzy-only (typo) match', () {
      test(
          'should score a one-char typo above a sensible include threshold (≥ 0.80)',
          () {
        // 'omeprzol' = 'omeprazol' with one deleted 'a' → edit distance 1.
        final double score = fuzzyNameScore('omeprzol', 'Omeprazol');
        expect(score, greaterThanOrEqualTo(0.80));
      });

      test('should cap a one-char typo score strictly below the contains band',
          () {
        // Because it is NOT a substring, it must be < 0.9 (contains band).
        final double score = fuzzyNameScore('omeprzol', 'Omeprazol');
        expect(score, lessThan(0.9));
      });

      test(
          'should score a transliteration-style one-char typo above 0.80 (magnij b6 vs Magniy B6)',
          () {
        // 'magnij b6' vs 'magniy b6' — 'j'→'y' is one substitution.
        final double score = fuzzyNameScore('magnij b6', 'Magniy B6');
        expect(score, greaterThanOrEqualTo(0.80));
      });

      test(
          'should cap the fuzzy score strictly below the contains band for magnij typo',
          () {
        final double score = fuzzyNameScore('magnij b6', 'Magniy B6');
        expect(score, lessThan(0.9));
      });

      test(
          'should score a clearly unrelated name well below 0.5 (below-threshold non-match)',
          () {
        // 'aspirin' vs 'Omeprazol' — completely different strings.
        final double score = fuzzyNameScore('aspirin', 'Omeprazol');
        expect(score, lessThan(0.5));
      });

      test('should keep fuzzy-only score at or below the documented max cap',
          () {
        // No non-substring match should exceed ~0.85 (the _maxFuzzyScore cap).
        final double score = fuzzyNameScore('omeprzol', 'Omeprazol');
        expect(score, lessThanOrEqualTo(0.85));
      });
    });

    // -------------------------------------------------------------------------
    // Substring-always-outranks-fuzzy invariant (AC-9 key invariant)
    // -------------------------------------------------------------------------

    group('invariant: substring always outranks fuzzy-only', () {
      test(
          'should score a true substring strictly above a non-substring one-char typo',
          () {
        // 'praz' IS a substring of 'Omeprazol'  → ~0.9 (contains band).
        // 'omeprzol' is NOT a substring (one deletion) → fuzzy-only, < 0.85.
        final double substringScore = fuzzyNameScore('praz', 'Omeprazol');
        final double fuzzyOnlyScore = fuzzyNameScore('omeprzol', 'Omeprazol');
        expect(substringScore, greaterThan(fuzzyOnlyScore));
      });

      test(
          'should score a prefix substring strictly above a non-substring near-match',
          () {
        // 'ome' is a prefix of 'Omeprazol' (~0.95).
        // 'omeprzol' is a one-char-deleted non-substring fuzzy score.
        final double prefixScore = fuzzyNameScore('ome', 'Omeprazol');
        final double fuzzyOnlyScore = fuzzyNameScore('omeprzol', 'Omeprazol');
        expect(prefixScore, greaterThan(fuzzyOnlyScore));
      });

      test(
          'should rank Cyrillic substring above a Cyrillic non-substring fuzzy match',
          () {
        // 'приm' IS a suffix-substring of 'Мексиприм' → contains band (~0.9).
        // 'мексипрем' has one substitution ('и'→'е'), not a substring → fuzzy-only.
        final double substringScore = fuzzyNameScore('прим', 'Мексиприм');
        final double fuzzyOnlyScore = fuzzyNameScore('мексипрем', 'Мексиприм');
        expect(substringScore, greaterThan(fuzzyOnlyScore));
      });
    });

    // -------------------------------------------------------------------------
    // Edge cases
    // -------------------------------------------------------------------------

    group('edge cases', () {
      test('should return 0.0 when query is longer than name with no overlap',
          () {
        // 'acetylsalicylicacid' vs 'ome' — huge distance, should be near 0.
        final double score = fuzzyNameScore('acetylsalicylicacid', 'ome');
        expect(score, lessThan(0.3));
      });

      test('should return 1.0 for a single-character exact match', () {
        expect(fuzzyNameScore('a', 'a'), equals(1.0));
      });

      test('should return 0.0 for an empty name and non-empty query', () {
        // Query is not empty; name is. Edit distance = query length, maxLength
        // = query length → similarity = 0.0.
        final double score = fuzzyNameScore('ome', '');
        expect(score, equals(0.0));
      });
    });
  });
}
