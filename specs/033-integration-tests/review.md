# Review Report: 033-integration-tests

**Date**: 2026-06-18
**Spec**: specs/033-integration-tests/spec.md
**Changed files**: 11 (2 production key-only, 5 integration-test, 2 docs, pubspec + lock)

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 7 — **PASS**

All four focus areas clean. Key confirmations:
- **Info** — Data isolation holds: production opens `driftDatabase(name: 'dosly')` (`lib/core/database/database.dart:56`); the smoke test uses `dosly_inttest` (`db_open_smoke_test.dart:36`) and the golden flow uses per-test system-temp files (`app_harness.dart:119-120`). No test path opens or mutates the real `dosly` DB.
- **Info** — Smoke-test deletion is path-safe (`db_open_smoke_test.dart:43-49`): paths built from OS-resolved `getApplicationDocumentsDirectory()` + fully-literal filenames (`dosly_inttest.sqlite`/`-wal`/`-shm`); no external input → no traversal (CWE-22/73 N/A); guarded by `existsSync()` and runs after `db.close()`.
- **Info** — Temp-file harness self-cleans (`app_harness.dart:117-137`): randomized `createTempSync('dosly_it')` dir, guarded recursive delete scoped to that dir only.
- **Info** — No PHI logging (constitution §4.2.1): no `print`/`debugPrint`/logger anywhere in `integration_test/`; fixture names/doses appear only in `expect` reason strings (synthetic, not real PHI).
- **Info** — No network/telemetry surface added; both new deps (`integration_test`, `path_provider`) are dev-scoped (`pubspec.yaml:59-60,76`) — absent from runtime `dependencies`.
- **Info** — Production changes are inert `ValueKey` additions only.

## Performance Review

- High: 0 | Medium: 0 | Low: 2 (informational) — **No app-performance impact**

- **Low (info)** — `add_medication_modal.dart:442`: chip key `ValueKey('medsForm_${option.key}')` is runtime-interpolated (cannot be `const` — `option.key` is dynamic). Allocated only while the picker grid is open; zero measurable impact. The other added keys are `const ValueKey` literals on already-non-`const` widgets → no const-promotion regression.
- **Low (info)** — `add_medication_golden_test.dart:27-34`: 8 full app boots (one per fixture) for isolation adds test wall-clock (~30–90s on CI) but is not user-facing; the right isolation/speed trade-off for 8 fixtures.
- Dev deps (`integration_test`, `path_provider`) are excluded from release builds → **0 bytes** shipped.

## Test Assessment

- AC items with test coverage: **10.5 of 11** (AC-5 partial)
- Verdict: **ADEQUATE**

Observed: `flutter test integration_test -d emulator-5554` → 9/9 (golden 8 + smoke 1); host 393/393; analyze clean. All 8 variants exercised end-to-end including the injection unit-dropdown non-default path (fixture 5, `doseUnitIndex:1` → asserts `doseUnit.name == 'mg'`) and both multi-time fixtures (tablet 08:00+20:00, inhaler 08:00+23:00 — both slots asserted via set comparison, `medication_fixtures.dart:421-430`).

### Gaps (none blocking)
- **AC-5 partial (Low)** — `expectPersisted` does not assert `time_slots.doseAmount`/`doseUnit`. These are always null in all 8 fixtures and the modal exposes no per-slot dose entry, so unreachable via current UI. `MedFixture` has no per-slot dose fields. Schema-level only.
- **Validation/error UI paths NOT covered (Medium, not AC-mandated)** — empty name, dose≤0, no time slots, course duration=0 do not drive the modal's SnackBar/validation branches on a real device. Host widget tests cover these with a fake repo; the spec's §3 matrix is 8 happy-path forms only. Genuine future opportunity, not a spec gap.
- **Start-date picker interaction untested (Low)** — driver leaves it at default (today); the default value IS asserted. No AC requires the picker interaction.
- **`createdAt` lower bound loose (Low)** — accepts the past 24h; upper bound is tight (now+1min). Very low risk.
- **`find.text(unit).last` finder (Low/info)** — used for the unit dropdown; works (and is asserted) but fragile if future forms add matching-text items.

### Correctly deferred (out of scope per spec §6)
Mark-intake & weekly-adherence golden flows (UIs not built), CI wiring, iOS simulator, edit/delete flows, `notes` column (not in UI).

## Notes for /verify
- No Critical/High findings anywhere; nothing blocks the feature.
- The one substantive forward-looking item is **validation/error-path coverage through the real UI** (Medium) — worth a follow-up spec, not a blocker here.
- Earlier in execution, the consolidated code review already caught and fixed a Critical (`startDate` `==` vs drift local-flag → `isAtSameMomentAs`); that fix is validated by the 9/9 on-device pass.
