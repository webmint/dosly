# Review Report: 041-today-redesign

**Date**: 2026-07-06
**Spec**: specs/041-today-redesign/spec.md
**Changed files**: 25 (9 source, 6 test, 1 integration test, 3 ARB + 4 generated l10n, 1 deletion, `.g.dart`)
**Task status**: 10/10 Complete · full `flutter test` 836/836 green · `dart analyze` clean

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 8
- **Overall: PASS**

dosly is local-only (no backend/network/accounts) — network/auth/CORS/transport/cert-pinning items are N/A. No exploitable vulnerabilities or constitution violations found.

- **Info** — `intake_providers.dart:134` (reconcile-on-open log): the sole new log call passes a static literal message + a `Failure` funneled through `sanitizeRecord` (`core/logging/log_sanitizer.dart`), which redacts `CacheFailure.message`/`NotFoundFailure.id`/`ValidationFailure.message`/etc. — a medication name embedded in a failure string can never reach a sink (CWE-532 mitigated). Constitution §4.2.1 PHI-logging rule satisfied.
- **Info** — `today_screen.dart:472` `_onMarkAllInGroup` and `_onTaken`/`_onSkip`/`_onUndo`: failures surface only the generic `todayActionError` SnackBar; no per-dose logging, no PHI in any path. `initState` reconcile is fire-and-forget, logs nothing.
- **Info** — All new/parameterized ARB strings interpolate only integers (counts/times), never a medication name or dosage; on-screen med names are display-only, never logged. en/de/uk error strings PHI-free.
- **Info** — `todayIntakeSettings` projects `intakeWindow`/`gracePeriod`/`allowMarkAhead` — non-PHI UI prefs from SharedPreferences; PHI stays in drift. SharedPreferences rule satisfied.
- **Info** — No unsafe patterns introduced across the 9 changed files: no `print`/`debugPrint`, no `!` null-assertion (constitution-forbidden), no unchecked `as`, no `jsonDecode`/deserialization, no `Process.run`, no string-built file paths. Null handling uses guarded `if (x == null) return` / `?? const []`.
- **Info** — Input validation adequate for the trust boundary: timer/countdown math consumes VO-clamped injected values; no external/untrusted input. Boundary timer guards against zero/negative durations (`today_screen.dart:313` `c.isAfter(nowUtc)`); countdown clamps negative remaining to zero.
- **Info** — Deleted `intake_grace.dart` (grace folded into injected `Duration`) has no security impact.

## Performance Review

- High: 0 | Medium: 0 | Low: 3
- **Nothing blocks shipping.** All findings are Low at realistic scale (personal tracker, < ~30 doses/day); two are pre-existing/documented trade-offs.

- **Low** — `today_screen.dart:472-497` (`_onMarkAllInGroup`) + `today_view_model.dart` (`buildTodayView`): Mark-all writes sequentially; each write re-emits `intakesListProvider` → a full `buildTodayView` re-derivation (O(doses+intakes)) per write. A handful of sub-ms recomputes at real volumes. **Recommendation**: no action now (accepted MVP trade-off per spec/plan/MEMORY); if a cross-group "mark all today" (20+ doses) is ever added, batch into one repository call for a single stream emission.
- **Low** — `due_dose.dart` (`_isDueToday` via `CourseProgress.resolve`) + `today_dose_tile.dart:186` (`_TileBody`): `CourseProgress.resolve` computed twice per course dose per build (once for due-today/phase, once per tile for the "Day N/M" chip). Each is O(1). **Recommendation**: optional DRY — thread the resolved `CourseProgress` through `TodayDose` (computed once in `_shapeDose`); not worth it for perf alone.
- **Low (§3.5 dead code)** — `today_view_model.dart:202-210` (`TodayView.doses` transitional getter): **grep confirms it is unused in production** — the screen and all widgets consume `view.groups`/`group.doses` (plain fields, O(1)) directly. Only the VM unit test (43 call sites) uses it, re-flattening per `expect`. Runtime cost today = zero, but it is unused production API and a latent O(doses) footgun. **Recommendation**: delete it once the VM test is migrated to iterate `groups`, OR explicitly mark it test-only. (Retirement already noted in data-model.md / task 005 notes.)

**Confirmed sound**: `buildTodayView` is a single O(doses+intakes) pass (no per-dose re-scan); the boundary `Timer` is a correct one-shot (strictly-future candidates, fire body is `setState` only, no DB writes — matches AC-5/AC-15); `ListView.builder` (lazy) for groups; `ValueKey`-stable group sections preserve collapse state across timer rebuilds.

## Test Assessment

- **AC items with test coverage: 9 of 16 solid** (AC-1, AC-4, AC-6, AC-7*, AC-9, AC-11, AC-12, AC-15, AC-16); 6 partial (AC-2, AC-3, AC-8, AC-10, AC-14); AC-13 verified by code-read (static property — no test needed).
- 78 feature tests across 6 files, all passing; ARB parity (en/de/uk) confirmed; DE/UK spot-checks present.
- **Verdict: GAPS FOUND** — the gaps are missing SCREEN-LEVEL integration assertions, not defects; the underlying behavior is implemented and unit-tested at the VM/use-case/widget layer.

### Coverage gaps (most important first)
- **AC-5 — live countdown update at a boundary**: no test proves `TodayCountdownCard`'s rendered value/target re-derives when the one-shot timer fires. The boundary test only asserts the checkbox locks after advancing past grace; it never has a second future dose to re-target and never reads the card text before/after. The AC's core claim is untested.
- **AC-8 — reactive to settings**: no test mutates `todayIntakeSettingsProvider`/`settingsNotifierProvider` on an already-mounted `TodayScreen` and asserts enablement flips live. Every screen test pins settings statically for the whole test (the mark-ahead test starts with it already `true`).
- **AC-14 — grace rewire at the screen level**: VM + `undo_intake` are thoroughly proven configurable, but no `today_screen_test` passes a NON-default `GracePeriod` via the `settings:` harness and observes Undo availability differ from the 5-min baseline (so the screen's `_onUndo → undoIntakeProvider(gracePeriod:)` wiring's variability is unproven end-to-end).
- **AC-10 — Mark-all "leaves others untouched" + failure path**: the screen Mark-all test has only actionable-pending doses in the group; no mixed group (taken/skipped/missed alongside pending) proves those are left alone. The per-dose-failure → error SnackBar path is untested anywhere (no failing `markIntakeTakenProvider` injected).
- **AC-2 — multi-dose group-state boundary**: VM tests only exercise single-dose groups for future/past/now; the "mixed future + past-window (no open dose) ⇒ now" multi-dose case (per `TodayGroupState.now`'s own doc) has no test.
- **AC-3 — minor**: chevron rotation angle not asserted; the "no now AND no future ⇒ nothing expanded" branch untested; ephemeral "resets on reload" not tested.
- **AC-7 — minor (a11y)**: skip icon's ≥48 dp tap target and tooltip string not asserted (both present in code).

### Recommendation for `/verify`
None of the gaps are blocking defects (behavior is implemented + green at the layer below). The highest-value additions before `/finalize` would be three screen-level tests: (1) AC-5 countdown re-target after a boundary; (2) AC-8/AC-14 combined — mount with mark-ahead-off / non-default grace, then flip the setting and assert enablement/undo-window changes; (3) AC-10 mixed-group Mark-all + a failure→SnackBar case. Plus the §3.5 cleanup of the dead `TodayView.doses` getter.
