# Research: Meds-List Search & Empty-State Fidelity

**Date**: 2026-06-18
**Signals detected**: Fuzzy-matching approach/algorithm not yet present in the codebase; a candidate package (`fuzzywuzzy`/`string_similarity`) not in `pubspec.yaml`. Spec left package-vs-pure-Dart as a `/plan` decision (OQ-1 resolved to Levenshtein; OQ-4 matcher placement open).

## Questions Investigated

1. **Which fuzzy algorithm/engine satisfies "typo-tolerant ranked" matching for medication names?** → Levenshtein (edit distance), normalized to a 0..1 similarity, is exactly the user's choice and handles the named cases with a plain whole-string pass: `lev("omeprzol","omeprazol")` = 1 edit / maxLen 9 ≈ **0.89**; `lev("magnij b6","magniy b6")` = 1 substitution ≈ **0.89**. No token logic needed for the required cases.
2. **Package vs pure-Dart?** → **Pure-Dart Levenshtein** (decision below). The algorithm is ~40 lines and the constitution favours minimal dependencies for a privacy-focused, local-only app (§2.3 forbids telemetry/abandoned packages; §3.6 KISS).
3. **How does fuzzy interact with the prefix/short-query case ("ome" → "Omeprazol")?** → A short query has a low whole-string Levenshtein similarity to a long name (would fall below threshold), so the spec's **substring guarantee (AC-6)** is essential: substring/prefix hits are always included and scored above fuzzy-only matches. As the user types "o"→"om"→"ome" the substring path keeps the row matched and live.
4. **Cyrillic case-folding & character counting?** → Dart `String.toLowerCase()` is Unicode-aware (Cyrillic upper/lower maps correctly). Levenshtein should iterate over **characters/runes** (BMP Cyrillic + Latin are single code units, so code-unit iteration is also safe here) — noted as an implementation detail.

## Alternatives Compared

### Fuzzy matching engine
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Pure-Dart Levenshtein** (hand-rolled in `core/utils`) | Zero dependencies (no §2.3 vetting, no supply-chain/abandonment risk); ~40 lines; full control of threshold + normalization + substring bonus; trivially unit-testable (AC-9); fits privacy/KISS ethos | Must own the normalization + ranking + (optional) token handling ourselves | **Chosen** |
| `fuzzywuzzy` (pub) | Levenshtein-based (matches the user's choice); pure Dart, one transitive dep (`collection`); ships `ratio`/`partialRatio`/`tokenSortRatio` + `extractTop` ranked extraction out of the box | Adds a dependency for a trivial algorithm; maintenance recency must clear §2.3 (>18mo unmaintained = forbidden) — staleness risk on a port; more surface than we need for short names | Rejected (good lib; not worth the dep here) |
| `string_similarity` (pub) | Popular; `findBestMatch` ranked API; returns 0..1 | Uses **Dice coefficient (bigrams), not Levenshtein** — contradicts the user's explicit Levenshtein choice; bigram similarity is weak on very short strings | Rejected (wrong algorithm) |
| `fuzzy` (pub) | fzf-style subsequence scoring | Subsequence, **not edit-distance** — the user rejected subsequence in favour of typo-tolerant Levenshtein | Rejected (wrong algorithm) |

**Decision**: **Pure-Dart Levenshtein** — own a small, generic, dependency-free scorer; it satisfies the Levenshtein requirement, sidesteps the §2.3 abandonment/telemetry risk entirely, and keeps the local-only app lean.

### Matcher placement (OQ-4)
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `lib/core/utils/fuzzy_name_match.dart` | Generic, feature-agnostic (reusable for future searchable lists — history, today's schedule); matches §2.2 "core/utils = truly generic helpers" | Slightly more visible surface | **Chosen** |
| Feature-local in `meds/presentation/` | Co-located with its only current consumer | Not reusable; would be moved later anyway | Rejected |

## References
- [fuzzywuzzy | Dart package](https://pub.dev/packages/fuzzywuzzy) — Levenshtein-based, pure Dart, `collection` dep; `ratio`/`tokenSortRatio`/`extractTop`.
- [dart-fuzzywuzzy (GitHub)](https://github.com/sphericalkat/dart-fuzzywuzzy) — port of Python fuzzywuzzy.
- [string_similarity | Dart package](https://pub.dev/packages/string_similarity) — Dice's coefficient (0..1), `findBestMatch` (not Levenshtein).
- Constitution §2.3 (package allowlist / forbidden categories), §3.6 (KISS), §3.7 (search before building), §2.2 (`core/utils` scope).
- `research/2026-06-18-meds-list-search.md` — feasibility research feeding this spec.
