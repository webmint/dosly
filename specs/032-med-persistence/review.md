# Review Report: 032-med-persistence

**Date**: 2026-06-17
**Spec**: specs/032-med-persistence/spec.md
**Changed files**: 32 hand-written source/test files (+ generated `*.g.dart`/`*.freezed.dart`/`app_localizations*.dart`)

## Security Review

- Critical: 0 | High: 0 | Medium: 1 | Info: 5
- **Overall: PASS** — no exploitable vulnerability, no constitution violation.

- **Medium** — `lib/core/database/database.dart` (`_openConnection` → `driftDatabase(name: 'dosly')`): SQLite DB is **unencrypted at rest** (CWE-311). All PHI (med names, dosages, schedules) is plaintext in the app sandbox.
  Recommendation: deliberate, documented MVP trade-off for the local-only/no-account threat model — **track as post-MVP hardening, not a blocker**. When the threat model expands: SQLCipher via `sqlcipher_flutter_libs` + `PRAGMA key`, key in platform keystore/keychain, and exclude the DB file from cloud backups (iOS `NSURLIsExcludedFromBackupKey`, Android `allowBackup=false`).

- **Info** — `medication_repository_impl.dart` `catch (e,st) → Left(Failure.unknown(e,st))`: **assessed, NOT a finding**. Drift exceptions *can* embed PHI, but every consumer was traced: the modal folds failures into generic localized SnackBars (never `.toString()`/`.error`/`.stack`); `Failure.unknown` is never passed to the logger in `lib/features/meds/`; and the logger's `sanitizeRecord` renders `UnknownFailure` type-only by default (error detail only in `kDebugMode`, release logging is `Level.OFF`). This is the prescribed pattern (MEMORY spec-022) and closes the bug-017 CWE-209/532 chain by construction.
- **Info** — Injection: clean. All persistence via drift typed companions/queries; the only raw statement is the constant `customStatement('pragma foreign_keys = ON;')`. No `customSelect`/`rawQuery`. CWE-89 N/A.
- **Info** — Secrets: clean. No hardcoded keys/tokens; IDs are UUIDv4; ARBs hold only UI strings; no tracked `.sqlite`/`.env`/keystore.
- **Info** — Input invariants: `Dosage`/`PackStock`/`MedicationId` are plain freezed holders with no non-negative/finite assertions; modal uses `tryParse … ?? 0` fallbacks (dose amount → 0 on blank; `warnAt` unbounded). Data-quality concern, not exploitable (local app). Optional hardening: constructor `assert`s for non-negative/finite values.
- **Info** — `medicationFromRows` fails loudly (`StateError` incl. `row.id`, a UUID not PHI) on corrupt course rows — good resilience.

## Performance Review

- High: 0 | Medium: 0 | Low: 4 (all Low / informational) — feature is clean for performance.

- **Low** — `add_medication_modal.dart:170` `_medFormOptions` is library-`final` (not `const`, due to closures): allocated once at load, shared. Correct pattern; no action.
- **Low** — `add_medication_modal.dart:1614` `onDurationChanged: (_) => setState(() {})` rebuilds the modal per keystroke in course mode. Cheap (bounded Column, no lists), within frame budget. Optional: scope the info-chip recompute to a `ValueNotifier`.
- **Low/Info** — DB open is deferred to first modal open and runs **off the UI thread** (`drift_flutter` `DatabaseConnection.delayed` on a background isolate). No synchronous UI-thread I/O. Forward-looking: when a meds **list** screen lands, warm `appDatabaseProvider` during splash/AppShell to avoid first-launch cold-open latency.
- **Low/Info** — `time_slots.medicationId` (FK) has **no secondary index**. Zero cost today (insert-only). When the list/query/cascade-delete feature ships, add `@TableIndex(name:'idx_time_slots_medication_id', columns:{#medicationId})` + bump `schemaVersion` to 2.
- Info — `const Uuid().v4()` per call: effectively zero-cost (canonicalized const). Auto-dispose providers + `ref.read` in `_onSave`: safe (use case held locally; `AppDatabase` is keepAlive).

## Test Assessment

- AC items with test coverage: **14 of 25 direct**; 7 indirect-only; 4 with no meaningful coverage (AC-3 + specific sub-gaps in AC-18/20/21).
- Full suite: 384/384 pass; `dart analyze` clean.
- Verdict: **GAPS FOUND**

Gaps (by priority):
- **Gap 1 (HIGH) — AC-20 modal per-form mapping**: all three modal Save tests use **Inhaler only** (null dose/null stock). The **Tablet** path (quantity stepper + stock card → `Dosage(tablet)` + `PackStock`) and **Syrup** path (dose field + unit dropdown → `Dosage(ml)`) are NOT exercised end-to-end through `_onSave`'s branching (`form.hasQuantity`/`hasDose`, `DoseUnit.values.byName`, `int.tryParse` stock guard). A regression in that branching passes the suite. The mapper unit test proves mapping in isolation but bypasses `_onSave`.
- **Gap 2 (MEDIUM) — AC-18**: `medsAddSaveErrorTimes` and `medsAddSaveErrorDuration` SnackBar branches untested in the modal (only name-error + success covered).
- **Gap 3 (MEDIUM) — AC-20 / W2 zero-dose**: blank dose field silently persists `Dosage(amount: 0.0)`; behavior is neither asserted-as-accepted nor rejected. No safety net if a dose>0 rule is later added.
- **Gap 4 (MEDIUM) — AC-20 PackStock partial-input**: the "only build PackStock when remaining+total both parse" rule (OQ-1) is untested in the modal.
- **Gap 5 (LOW) — AC-16**: mapper tests use `isAtSameMomentAs`, not `isUtc == true` (drift reads back local-flagged DateTimes). UTC requirement satisfied by source, not asserted.
- **Gap 6 (LOW) — AC-3**: no test verifies provider `keepAlive` + `ref.onDispose(db.close)`.
- **Gap 7 (LOW) — AC-14**: failure test induces a medication-row PK clash (pre-slot); transactional **rollback** after a partial write (slot-level failure leaving no orphan medication row) is not exercised.
- **Gap 8 (LOW) — AC-18/21**: de/uk **error/success SnackBar** strings not asserted (only titles are, per-locale).

## Cross-task carry-over (from execution)
- **T008 W1**: `medication_mapper.dart` read-back `warnAt ?? 0` silent default (non-triggering; optional hardening to `StateError`).
- **W2**: the zero-dose gap above (Gap 3) — flagged at task 011.

## Post-review fixes (2026-06-17) — all 4 Warnings RESOLVED
Applied after `/verify` (architect + mobile-engineer + qa-engineer), code-reviewed APPROVE, full suite **393/393**, analyze clean:
- **W2 / Gap 3 (zero-dose)** → RESOLVED: `AddMedication` now returns `ValidationFailure(field: 'dose')` when `dosePerIntake != null && amount <= 0`; new `medsAddSaveErrorDose` string (en/de/uk); modal maps `'dose'`. Covered by a use-case test (zero + negative) and a modal dose-error widget test.
- **T008 W1 (warnAt silent default)** → RESOLVED: mapper now throws `StateError` when stockRemaining+stockTotal present but stockWarnAt null (symmetric with the course guard). Covered by a corrupt-row in-memory mapper test.
- **Gap 1 (modal per-form mapping e2e)** → RESOLVED: added Tablet + Syrup Save widget tests that capture the built `Medication` via a recording fake repo and assert `dosePerIntake`/`stock`/`form`; plus a PackStock partial-input test (only `remaining` → `stock == null`).
- **Gap 2 (times/duration SnackBar branches)** → RESOLVED: added modal tests for `medsAddSaveErrorTimes` and `medsAddSaveErrorDuration`.
- Remaining (accepted, not addressed): unencrypted-at-rest (post-MVP backlog); FK index + DB warm-up (deferred to the meds-list spec); UTC-flag/provider-dispose/rollback/de-uk-SnackBar Info gaps.
