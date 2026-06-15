## Feature Summary: 030 — Add-Medication Intake-Type Control

### What was built
The Add-medication form now lets you choose how a medication is taken: a **Continuous / Course** segmented toggle placed after the intake-time chips. Picking **Course** reveals a course-parameters card — Duration (days), Pause (days), a tappable **Start date** (native date picker), and a live "Course: <start> — <end> (N days)" info chip that recomputes as you edit. This is iteration 5 of the visual build: everything is local UI state, Save remains a no-op, and nothing is persisted yet.

### Changes
- Task 001: Add intake-type & course l10n keys (en/uk/de) — added 9 `medsAdd*` strings incl. the project's first ICU-plural + placeholder message (`medsAddCourseRangeLabel`), regenerated localizations.
- Task 002: Build the intake-type section in the modal (+ promote `clock`) — added `_IntakeType` enum, a `_CourseCard` widget, the `SegmentedButton`, the date picker, and the live info-chip computation; promoted `clock` to a direct dependency for a testable "today" default.
- Task 003: Widget tests for the intake-type section — 11 new `testWidgets` covering AC-3…AC-11 (default state, reveal/hide, date picker cancel/confirm, live range, fallbacks, uk plural), with `withClock` for deterministic dates.

### Files changed
- `lib/features/meds/presentation/widgets/` — 1 file modified (the modal)
- `lib/l10n/` — 3 `.arb` files modified + 4 generated localization files regenerated
- `pubspec.yaml` / `pubspec.lock` — `clock` promoted transitive → direct
- `test/features/meds/presentation/widgets/` — 1 file modified (+11 tests)

[Total: 11 files changed, 946 insertions, 7 deletions]

### Key decisions
- Default = **Continuous** (course card hidden on open); info chip is **live-computed** (`end = start + (duration − 1)` days, inclusive) — matches the HTML "Mar 26 + 7 → Apr 1".
- Default start date = `DateUtils.dateOnly(clock.now())` via `package:clock` (constitution §8; test-overridable with `withClock`) rather than `DateTime.now()`.
- Day count uses a **single ICU-plural message** mixing a `{range}` String placeholder + `{count}` plural (uk `one/few/many/other`) — no manual pluralization, no second composed key.
- Dates rendered with `MaterialLocalizations.formatMediumDate` (no new `intl`/`DateFormat` dependency); the `_CourseCard` is presentation-pure (receives a precomputed `infoLabel`).

### Acceptance criteria
- [x] AC-1: Intake-type section renders after the time chips, before Save
- [x] AC-2: SegmentedButton with exactly two segments (Continuous / Course)
- [x] AC-3: On open, Continuous selected, course card absent from tree
- [x] AC-4: Tapping Course reveals the course-parameters card
- [x] AC-5: Tapping Continuous removes the card
- [x] AC-6: Card shows header, Duration (default 7), Pause (default 0), start-date field, info chip
- [x] AC-7: Start date defaults to today (`clock.now()`), locale-formatted
- [x] AC-8: Start-date field opens `showDatePicker`; confirm updates, cancel leaves unchanged
- [x] AC-9: Valid duration → inclusive range + pluralized day count; updates live
- [x] AC-10: Empty/invalid duration → start-only fallback, no crash
- [x] AC-11: Strings in en/uk/de incl. correct uk plural; no hardcoded strings
- [x] AC-12: New Duration/Pause controllers disposed
- [x] AC-13: Save stays a no-op; no domain/data; nothing persisted
- [x] AC-14: `dart analyze` clean; 324/324 tests pass; new tests cover AC-3…AC-10
