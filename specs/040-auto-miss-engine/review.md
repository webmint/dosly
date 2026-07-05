# Review Report: 040-auto-miss-engine

**Date**: 2026-07-05 (re-review after test-only gap fixes)
**Spec**: [spec.md](spec.md)
**Changed files**: 19 (11 production incl. 3 ARB, 8 test/harness) + generated `.g.dart`/`app_localizations*`

> This is a re-run of `/review`. Since the first review, **zero production (`lib/`) code changed** — only the 4 test files (gap fixes) + docs. The Security and Performance findings below are therefore carried forward unchanged (production is byte-identical); the Test Assessment was re-run fresh and now reads **ADEQUATE** (all 6 previously-found gaps closed with falsifiable tests).

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 2 — **PASS** (unchanged; production code byte-identical since first review)

- **Info** — `lib/features/meds/presentation/providers/intake_providers.dart` (`reconcileMissedOnOpen` log call): intake-failure path is fully redacted (`CacheFailure` → `‹redacted›`), but the **medication** snapshot read surfaces `Failure.unknown(e, st)`, which the sanitizer emits verbatim when `includeErrorDetail` (`kDebugMode`) is true. In **debug builds only**, a drift `SqliteException` detail (errstr/SQL, possibly DB file path — **not** medication-name data) could reach `developer.log`; release builds suppress all logs. CWE-209, **no §4.2.1 PHI violation**. Pre-existing `MedicationRepositoryImpl` inconsistency **surfaced, not caused** by feature 040.
  Recommendation (**out of feature-040 scope — tracked follow-up**): have `MedicationRepositoryImpl.watchAll` return `Failure.cache(...)` (fully redacted) for parity with the intake repo.
- **Info** — `lib/features/meds/presentation/screens/today_screen.dart:93`: the Today-load trigger discards the reconcile `Either` without folding/logging the `Left`. Not an error-swallow (a `Left` is a returned value, not an uncaught throw) and not a data-loss risk (insert-or-ignore + idempotent retry); the on-open path already logs. Purely cosmetic. **Not addressed** (deliberate).

**Verified safe:** two-layer never-clobber (calendar-day eligibility exclusion + DB `insertOrIgnore`, never `DoUpdate`); parameterized drift companion writes (no raw SQL); `ReconcileMissedIntakes.call` never throws (startup can't crash); no secrets/network/new permissions/insecure storage; nothing writes PHI to SharedPreferences; no debug artifacts in production.

## Performance Review

- High: 0 | Medium: 3 | Low: 4 — **PASS** (unchanged; opportunistic, none blocking at this app's local-only, single-user, small-table scale). **Not addressed** (deliberate — all opportunistic).

- **Medium** — `reconcile_missed_intakes.dart` (`watchAll().first` ×2): two drift `.watch()` subscriptions per reconcile just to grab one emission — structurally the wrong tool for a snapshot (no leak; `.first` cancels). This is the plan's **OQ-1 trade-off** (chosen `.first` to avoid the `MedicationRepository` fake blast radius). Recommendation: a one-shot `getAllOnce()`/`.get()` read path if ever profiled to matter.
- **Medium** — `reconcile_missed_intakes.dart` write loop: N un-batched `markMissed` → N `intakes` change notifications → `intakesListProvider` re-emits N times → N `ListView` rebuilds. N bounded by today's slot count (self-limiting; typically 0–1). A naive `transaction()` wrap would break the documented fail-fast **partial-durability** contract. Recommendation: `db.batch()` the all-succeed path only if profiling shows it matters.
- **Medium** — cold-start double-fire: `AppBootstrap` fires `reconcileMissedOnOpenProvider` AND the initial `/` route `TodayScreen.initState` independently fires `reconcileMissedIntakesProvider` — both run on first launch. Correct (idempotent + insert-or-ignore) but doubles startup DB I/O. Recommendation: skip the `initState` fire when the on-open future is in flight, or drop one trigger — only if startup contention ever shows.
- **Low (confirmed non-issues)**: derivation O(doses + intakes), no O(n²); startup non-blocking (fire-and-forget `ref.read`, background-isolate DB, `Future.microtask`); missed tile is a static `Text`; single-fire test proves no reconcile↔rebuild loop.
- **Low (context, pre-existing)**: `intakes` table has no retention/pruning; both the render path and the reconcile scan full intake history — 040 performs that scan a second time per trigger. Consider date-scoped queries if history grows.

## Test Assessment

- AC items with test coverage: **15 of 15** — all covered with genuine, falsifiable assertions.
- **Verdict: ADEQUATE** (re-assessed 2026-07-05). Full suite **798/798** green, project-wide `dart analyze` clean, ~14s (no hang).

The 6 gaps from the first review are all **CLOSED**, each verified falsifiable (not a lying comment / can't-fail check):

1. **AC-10 trigger-fires** — `app_bootstrap_test.dart` asserts `container.exists(reconcileMissedOnOpenProvider)`. Verified: `exists` inspects element-existence without creating it (Riverpod source), and that wrapper is read ONLY from `app_bootstrap.dart:81` (`TodayScreen` reads the *different* `reconcileMissedIntakesProvider`), so it can't false-positive; deleting the trigger line fails the test.
2. **AC-10 failure-swallow** — reads `container.read(reconcileMissedOnOpenProvider).hasError == false` (plus no-error-screen); a rethrow-instead-of-fold flips `hasError` and fails it.
3. **AC-12 idle-no-flip** — mutable clock + bounded `pump(Duration(hours:3))` past the window-close while mounted (reconcile no-op'd) → tile stays pending, intakes table empty; terminates (no hang).
4. **AC-11 no-meds (use-case layer)** — `stubMeds([])` → `Right(0)` + `verifyNever(markMissed)`.
5. **AC-5 fresh IntakeId** — asserts written ids == `miss-id-1`/`miss-id-2` (specific minted values, per occurrence).
6. **AC-9 schemaVersion** — `expect(db.schemaVersion, 2)`.

No new gaps introduced (all additions strictly additive, fresh DB/container per test); no regressions in previously-solid areas (AC-1..4 derivation incl. strict-boundary/DST/exclusion; AC-6 idempotency; AC-7 two-layer never-clobber with real-DB read-back; AC-8 Either/CacheFailure; AC-9 round-trip; AC-11 once-per-mount/no-loop; AC-12 reactive-on-load; AC-13 display-only tile; AC-14 en/de/uk; AC-15 process).

## Consolidated verdict for /verify

- **Security**: PASS (2 Info — both deliberately not addressed: #1 pre-existing/other-file → tracked follow-up; #2 cosmetic).
- **Performance**: PASS (3 Medium — all opportunistic/non-blocking, deliberately not addressed → tracked follow-ups).
- **Tests**: **ADEQUATE** — 15/15 ACs covered; the 6 first-review gaps closed and independently verified falsifiable. Full suite 798/798, analyze clean. No production defect found or introduced.
