# Review Report: 034-meds-list

**Date**: 2026-06-18
**Spec**: specs/034-meds-list/spec.md
**Changed files**: 23 `lib/` (16 source + 7 l10n/generated) + 9 test files
**Status**: all 13 tasks Complete; full suite 481/481 green; `dart analyze` clean

## Security Review

- Critical: 0 | High: 0 | Medium: 1 | Info: 6 — **Overall: PASS**

- **Medium** — `lib/features/meds/presentation/screens/meds_screen.dart` (error branch, ~line 142) [CWE-209]: the `AsyncValue.when(error:)` branch renders `e.toString()` directly into a `Text`. When `medicationsList` rethrows an `UnknownFailure(error, stack)` (the repo wraps every drift `SqliteException` and every corrupt-row `StateError` this way), the raw text can embed SQLite internals or a corrupt-row's `row.id` / stock / duration values. Held to Medium (not High) because dosly is local-only (no transmission; reaches only the device owner's screen) and the corrupt-row `StateError` messages deliberately exclude `row.name` (the primary PHI field).
  Recommendation: in the `error:` branch, show a localized generic message (e.g. a new `medsListLoadError` key) instead of `e.toString()`; reserve raw detail for `kDebugMode`. Mirrors the redact-by-default policy in `log_sanitizer.dart`.

- **Info** — No new logging sink introduced; the `Failure.unknown` CWE-209/532 concern remains correctly forward-filed against bug 017 (typed-logger sanitize layer). This feature adds no live sink (no `ProviderObserver`, `FlutterError.onError`, or `runZonedGuarded`); the thrown `Failure` is consumed only by the on-screen `.when(error:)`.
- **Info** — PHI/logging clean: the seeder performs zero logging; the `.fold((_) {}, (_) {})` discard is documented best-effort (not a silent swallow); corrupt-row `StateError`s print `row.id`/durations/stock but NOT `row.name`.
- **Info** — Debug seeder safe: double-gated against release (`kDebugMode` at the call site AND in the provider body; `kDebugMode` is `const` → tree-shaken out of release), idempotent (empty-table guard), and contains no `delete`/`clear`/`drop`/`update`/`customStatement` — it can only `add`. No path wipes or mutates existing health data.
- **Info** — No injection surface: search/filter is pure in-memory Dart (`String.contains`); persistence uses drift typed companions + a typed `leftOuterJoin` — no raw SQL, no `customStatement`.
- **Info** — No network / telemetry / cloud anywhere in the changed files (local-only privacy default preserved).
- **Info** — Unsafe-pattern scan clean: no `!`, no unchecked `as`, no empty `catch` in any changed file.

## Performance Review

- High: 0 | Medium: 0 | Low: 3 (+ 5 confirmed fine-as-is) — **No actionable findings at the expected scale (5–50 meds, 1–3 slots each).**

- **Low** — `meds_list_view_model.dart:170` / `:135`: `_byNameCaseInsensitive` + the search filter allocate `toLowerCase()` strings per comparison/item. ~hundreds of short-lived strings per build — harmless at ≤50 items; premature to optimize. (Future: pre-compute normalized names if the list ever scaled to thousands.)
- **Low** — `meds_screen.dart:152–158`: `buildMedsListView` recomputes on every `setState`, including the search-toggle (`_searchOpen`) which doesn't change `meds`/`filter`/`query`. Sub-millisecond at ≤50 meds (frame budget 16 ms) → no jank. (Future: memoize `MedsListView` keyed on `(meds, filter, query)` only if a high-frequency `setState`/animation is added.)
- **Low** — `medication_display.dart:44–46`: `formatTimes` makes a defensive sort copy per tile build — trivial for 1–3 slots; the copy is correct (avoids mutating the entity). Fine as-is.
- **Fine as-is** — `clock.now()` once/build; `async*` bridge in `watchAll()` (one alloc per DB change event); watched join coalesces per-transaction (insert med + N slots = 1 emission, no N+1); `Column`-per-section is defensible until ~150 items/section (`ValueKey`s already in place for a mechanical `ListView.builder` migration); `medicationsListProvider` autoDispose lifecycle is correct (no leak, drift ref-counts the watcher); `closeStreamsSynchronously` is test-only.

## Test Assessment

- AC items with test coverage: **16 of 19** — Verdict: **GAPS FOUND**
- Feature tests: ~147 (full suite 481/481 green). Strong coverage of the temporal derivations (AC-4/5/6), data layer (AC-1/3), view-model (AC-7/10/11), and screen rendering (AC-8/12/13/14/19).

Gaps:
- **AC-9 (Medium)**: the **"Paused" type-chip branch is never rendered in a widget/screen test**. `course_progress_test` proves `CourseProgress.resolve` produces `CoursePhase.paused`, but no `MedicationTile`/`MedsScreen` test builds a paused-cyclic fixture and asserts the "Paused"/"Пауза" chip appears. The rendering branch is widget-test-dead.
- **AC-16/17/18 (Medium)**: the **debug seeder is entirely untested**. `devSeedMedications(now)` is a pure function (no I/O, no Flutter) and easily unit-testable, yet has zero tests. The B12 paused near-miss (caught only by code review) would have been caught by a test asserting `CourseProgress.resolve(b12.type, now).phase == CoursePhase.paused`. Recommended pure-function asserts: 12 entries; all 8 forms present; one each of continuous / non-cyclic-active / cyclic-active / cyclic-paused / completed; B12 → paused; Magnesium B6 → `isLowStock`; no id/slot-id collisions. (The `kDebugMode`/empty-table guards can't be unit-tested without flag manipulation — acceptable.)
- **AC-2 (Low)**: `medicationsListProvider`'s `Either` fold (`Left → throw`) is covered only end-to-end (repo tests + screen error branch uses a stream-error fake), never as a Riverpod unit test exercising a `Left`-emitting stream.
- **AC-15 (Low)**: de/uk locale coverage in widget tests is limited to `medsListTitle` only; section headers, filter/status/type chips, and the parameterized keys are not asserted under de/uk (a translation/plural error in those arb entries would go undetected). `medication_display_test` loads only `en`.

## Net assessment for /verify

No Critical or High findings; no constitution violation. The feature is functionally complete, performant for its scale, and the full suite passes. Outstanding items are quality hardening, not correctness blockers:
1. (Medium, security) Localized generic error string instead of raw `e.toString()` on the meds screen error branch.
2. (Medium, test) A pure unit test for `devSeedMedications(now)` covering the 12-variant / cyclic-paused / low-stock guarantees (AC-16/17).
3. (Medium, test) A widget test rendering the "Paused" type chip (AC-9).
4. (Low) Provider-fold unit test (AC-2); de/uk widget-locale assertions (AC-15).
