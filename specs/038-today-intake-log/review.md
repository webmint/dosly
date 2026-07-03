# Review Report: 038-today-intake-log

**Date**: 2026-07-03 (re-review after `/fix` closed all prior warnings)
**Spec**: specs/038-today-intake-log/spec.md
**Changed files**: production intake slice + Today UI + first drift migration + full test mirror (681 tests)

> This is a re-review run AFTER the `/fix` batch that closed the 6 warnings from the first review (see git history: `[WIP] Fix: close verify warnings …`). The first review's findings and their resolution are folded in below.

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 2

**Overall: PASS** (re-confirmed). No PHI (medication names/dosages/intake data) is logged anywhere; error SnackBars/text are generic localized strings; the PHI sanitizer choke-point is not bypassed; the add-only migration cannot lose/expose v1 data; all drift access is parameterized (no injection surface); `allowBackup=false` intact; no network dependency added. The only production change since the first review — the `buildTodayView` map refactor — is a pure in-memory transform (no logging/PHI/I/O), security-neutral.

- **Info** — `intake_repository_impl.dart:37,47,57,67`: `Failure.cache('…: $e')` embeds the raw `SqliteException` (CWE-209/532) but is non-leaking (never logged, never rendered raw; sanitizer redacts `CacheFailure.message` at the sink). Preserve that contract. *(unchanged)*
- **Info (pre-existing, out of scope)** — `meds_screen.dart:209`: renders `e.toString()` on stream error (CWE-209). Feature 038's Today screen correctly avoids this; align `meds_screen` in a separate change. *(unchanged)*

## Performance Review

- High: 0 | Medium: 1 (documented deferral) | Low: 4

- **CLOSED (was Medium)** — `today_view_model.dart` `buildTodayView`: the O(doses × intakes) linear rescan + per-pair `localCalendarDate` allocation is **resolved**. It now pre-indexes intakes once into `Map<(String,String,DateTime), Intake>` (each `localCalendarDate` computed once per intake) and does an O(1) lookup per dose → **O(doses + intakes)**. Behavior-preserving (verified: 11 view-model tests pass unedited; dead "prefer non-pending" fallback correctly removed since the DB unique key guarantees ≤1 intake per occurrence). No regression introduced.
- **Medium (documented deferral)** — `intake_local_data_source.dart:37` `watchAllIntakes()` streams the whole unbounded table. Sound for now; date-scope it + add a `scheduledAt` index when the History feature lands (it needs range queries anyway). *(unchanged, out of scope for this feature)*
- **Low (no action)** — grace `Timer` (one-shot, rescheduled, cancelled correctly); `ListView.builder` with stable keys; async `watchAllIntakes` on boot; index coverage. *(all unchanged, fine)*

## Test Assessment

- AC items with test coverage: **15 of 15 fully covered** (was 12/15 fully + 3 partial)
- Verdict: **ADEQUATE**

All previously-found gaps are closed with real, production-code-matching assertions (verified by reading both the test bodies and the exact production code they exercise):

| Prior gap | Status | Evidence |
|-----------|--------|----------|
| AC-11 error path + `IntakeRepositoryImpl` untested | **CLOSED** | new `intake_repository_impl_test.dart` (11 tests: watchAll/markTaken/skip/undo happy + `Left(CacheFailure)` failure paths); `today_screen_test.dart` error-state group drives `intakesList` to `AsyncValue.error` and asserts `todayLoadError` renders. |
| `MarkIntakeTaken`/`SkipIntake` no isolated units | **CLOSED** | new `mark_intake_taken_test.dart` / `skip_intake_test.dart` — `captureAny` asserts built `Intake` (status, minted `IntakeId`, UTC timestamps incl. local→UTC normalization, `notes==null`) + failure passthrough. |
| AC-14 no DE/UK locale spot-check | **CLOSED** | `today_dose_tile_test.dart` renders under `Locale('de')` (`Einnehmen`/`Überspringen`) and `Locale('uk')` (`Прийняти`/`Пропустити`) — real translated-string assertions. |
| AC-10 no negative styling assertion | **CLOSED** | `today_dose_tile_test.dart` past-vs-future pending test asserts identical affordances AND untinted `primaryContainer` badge on both — catches a one-sided overdue-tint regression. |
| FK cascade untested | **CLOSED** | `intake_local_data_source_test.dart` seeds med+slot+intake, deletes the med via the real `deleteMedication` path, asserts the intake row is gone (real `onDelete: cascade` + FK pragma). |

**Strengths retained**: rigorous migration data-survival proof; AC-13 grace tested at all three layers; `buildTodayView` behavior fully re-covered by the unedited view-model suite after the refactor.

**Non-blocking note (latent, dormant)**: the new map index is last-write-wins on key collision vs. the old scan's "prefer non-pending"; safe today because `pending` is never persisted (only `MarkIntakeTaken`/`SkipIntake` write rows, always taken/skipped) — a future change that persisted `pending` would make this untested/silently different. Documented in the code comment's own reasoning.

## Consolidated verdict inputs for `/verify`
- **Security: PASS** (2 Info, non-blocking, unchanged).
- **Performance: prior Medium CLOSED**; 1 documented deferral remains (out of scope).
- **Tests: ADEQUATE** — 15/15 ACs covered; 681/681 green; `dart analyze` clean.
- No Critical/High findings anywhere; no constitution violations. Feature is clean and ready to finalize.
