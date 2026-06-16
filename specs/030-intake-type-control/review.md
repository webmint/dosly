# Review Report: 030-intake-type-control

**Date**: 2026-06-15
**Spec**: specs/030-intake-type-control/spec.md
**Changed files**: 6 code/config files — `lib/features/meds/presentation/widgets/add_medication_modal.dart`, `lib/l10n/app_{en,uk,de}.arb` (+ generated `app_localizations*.dart`), `pubspec.yaml`, `pubspec.lock`, `test/features/meds/presentation/widgets/add_medication_modal_test.dart`

> All 3 tasks are Complete. This is a visual-only UI iteration (no persistence, no domain/data, Save is a no-op).

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 5
- **Overall: PASS**

Findings (all Info / hardening only — no CWE-classified issues):

- **Info** — `add_medication_modal.dart` (`_courseInfoLabel`, ~L1230): `_startDate.add(Duration(days: n - 1))` consumes the user-typed duration. An absurdly large pasted integer could make `Duration`/`DateTime.add` throw. Not exploitable (local-only, no PHI, no persistence), but a `n <= maxDays` clamp would harden the info chip. Robustness nicety, not security.
- **Info** — Visual-only claim verified TRUE against the diff: no `print`/`debugPrint`/`developer.log`/typed-logger calls anywhere in the widget or test; no medication name, duration, or pause value is logged → constitution PHI-logging rule satisfied.
- **Info** — No persistence / no data leaving device: no `SharedPreferences`, `flutter_secure_storage`, `drift`, `path_provider`, `Dio`/`http`/`HttpClient`, or `jsonEncode/Decode`. All new state is local widget `State`, disposed in `dispose()`. Save remains a confirmed no-op.
- **Info** — `clock: ^1.1.1` (resolved 1.1.2) promoted transitive→direct: official Dart-team package, no known CVEs, used only for `clock.now()` (test-overridable). `pubspec.lock` shows only the dependency-kind flip — no version downgrade, no new transitive packages (sha256 unchanged).
- **Info** — `showDatePicker` is framework-provided and bounded (`firstDate`/`lastDate`); `int.tryParse` null-guards malformed duration. No injection, deserialization, deep-link, file, or WebView surface introduced.

## Performance Review

- High: 0 | Medium: 0 | Low: 1
- **Overall: Clean — no changes recommended for this iteration.**

- **Low** — `add_medication_modal.dart:~1377` (`onDurationChanged: (_) => setState(() {})`): each duration keystroke rebuilds the full `_AddMedicationModalState.build` (~10 children). This matches the existing `setState` scope used by every other interaction in this modal; Flutter element-diffing reconciles stable/`const`/keyed subtrees cheaply, and `_CourseCard` is a `StatelessWidget` rebuilt with precomputed props. Per-keystroke work (`int.tryParse` + one `DateTime.add` + two `formatMediumDate` + ~10-slot diff) is well under the 16ms budget.
  Recommendation: a `ValueNotifier` + `ValueListenableBuilder` scoped to just the info chip is the cleaner long-term pattern (~0.5–1ms saving/keystroke), but it optimizes a non-bottleneck — **defer** until the modal is wired to real state management.

Other areas assessed and clean: controller lifecycle (both new controllers disposed, no leak); `_courseInfoLabel` cost (negligible, skipped entirely in default Continuous state); `clock` dependency (already transitive → zero release-binary/startup impact); `SegmentedButton` `{_intakeType}` set literal per build (one tiny allocation, negligible).

## Test Assessment

- AC items with test coverage: **8 of 9 assessed (AC-3 … AC-11)** — happy paths solid; some boundary/locale gaps.
- **Verdict: GAPS FOUND** (none blocking; the new 11 tests cover AC-3…AC-10 happy paths + `withClock` determinism + both date-picker branches)

Per-AC mapping:

| AC | Status | Note |
|----|--------|------|
| AC-1 | Missing | No test asserts section placement (after time chips, before Save). Low risk. |
| AC-2 | Partial | Button present + Course tappable, but `segments.length == 2` not asserted. Low. |
| AC-3 | Covered | Segmented button present; course card absent on open. |
| AC-4 | Covered | Tapping Course reveals card. |
| AC-5 | Covered | Tapping Continuous removes card. |
| AC-6 | Partial | Duration(7)/Pause(0)/field keys asserted; header row (icon + `medsAddCourseParamsTitle`) and "all six elements in one assertion" not checked. Low. |
| AC-7 | Covered | `withClock(2026-03-26)` → start field shows "Thu, Mar 26". |
| AC-8 | Covered | Cancel (unchanged) + confirm (date+chip update), both guard `DatePickerDialog`. |
| AC-9 | Covered | Default 7 → "Wed, Apr 1" + "7 days"; live-update 3 → "Sat, Mar 28" + "3 days". |
| AC-10 | Covered | Empty + non-numeric "abc" → `medsAddCourseStartOnly` fallback, no crash. |
| AC-11 | Partial | uk one/few/many tested (1/2/5); **German locale not tested**; uk `other` (11/21) not tested. |
| AC-12 | Missing | No test exercises/asserts controller disposal. Medium. |
| AC-13 | Missing | No test taps Save asserting no-op / no persistence. Low (visual-only). |

Coverage gaps (prioritized):
1. **Medium** — AC-9 duration boundary `n = 0` and negative: fallback branch (`n >= 1`) handles them correctly but is untested for these values (only empty/non-numeric tested).
2. **Medium** — AC-11 German locale: AC names en/uk/de but no `de` plural test exists.
3. **Medium** — AC-12 controller dispose: no test verifies `_durationController`/`_pauseController` disposal (real leak risk on mobile; could use `addTearDown` leak surfacing).
4. **Low** — AC-1 placement, AC-2 exact segment count, AC-6 header row, AC-11 uk `other` category, AC-13 Save no-op.

## Reviewer Summary (for /verify)

No Critical or High findings in any dimension. Security PASS, performance clean. The actionable items are all in test coverage — three Medium gaps (zero/negative duration boundary, German-locale plural, controller-dispose) and several Low. None block the feature; `/verify` should decide whether to require closing the Medium gaps before finalizing. Two non-blocking carry-overs from code review: `clock` was hand-added to `pubspec.yaml` (should be `flutter pub add` — logged to MEMORY), and `showDatePicker`'s window derives from `_startDate` rather than `clock.now()` (spec-accepted, no assertion risk).
