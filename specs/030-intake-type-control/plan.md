# Plan: Add-Medication Intake-Type Control (visual-only, iteration 5)

**Date**: 2026-06-15
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Add an "Intake type" section to `AddMedicationModal` — an inline `SegmentedButton<_IntakeType>` (Continuous / Course) that, when Course is selected, reveals a new `_CourseCard` private widget (Duration, Pause, a `showDatePicker` start-date field, and a live-computed date-range info chip). The work is entirely in the presentation layer plus three `.arb` files; the only cross-cutting change is promoting the already-transitive `clock` package to a direct dependency so the default start date is `clock.now()` (testable via `withClock`). Save stays a no-op; nothing is persisted.

## Technical Context

**Architecture**: Presentation only (`lib/features/meds/presentation/widgets/`). No domain/data layers touched. One infra change: `pubspec.yaml` dependency promotion + l10n source/generated files.
**Error Handling**: N/A — no fallible operations (no `Either`/repository). The only "error path" is invalid Duration input, handled by an `int.tryParse` null/`< 1` fallback in the info chip (AC-10).
**State Management**: Local `StatefulWidget` state in `_AddMedicationModalState` (no Riverpod) — consistent with specs 026–029 visual-only iterations.

## Constitution Compliance

| Rule | Status | Notes |
|------|--------|-------|
| §2.1 layer boundaries (no `data/` in presentation) | ✅ Compliant | Pure presentation; no domain/data added. |
| §8 "Clock injection over `DateTime.now()`" | ✅ Compliant | Uses `clock.now()` from `package:clock` (promoted to direct dep); `DateUtils.dateOnly` normalizes to a date. Tests override via `withClock`. |
| §7.4 strict lint (no `!`, no `dynamic`, `strict-*`) | ✅ Compliant | `_IntakeType` enum (no magic strings); `int.tryParse`; `SegmentedButton` `selection.isEmpty` guard before `.first`; null-safe throughout. |
| "Document new code" (dartdoc on public/private widgets) | ✅ Compliant | `_IntakeType`, `_CourseCard`, new state fields, and `_pickStartDate` get `///` docs mirroring existing in-file style. |
| "Never leave Flutter imports in `domain/`" | ✅ N/A | No domain code. |
| L10n in all three arbs; generated files via gen-l10n | ✅ Compliant | New keys added to en/uk/de; `app_localizations*.dart` regenerated, never hand-edited. |
| "Search before building" | ✅ Compliant | Reuses `SegmentedButton` (theme_selector), `_StockCard` card shape, the `showTimePicker` await/`mounted` idiom, and `formatTimeOfDay`→`formatMediumDate`. No new generic utilities. |
| Commit attribution / WIP convention | ✅ Compliant | Handled by `/execute-task` + `/finalize`. |

**No violations.** The single notable decision — adding a direct dependency in a "visual-only" iteration — is sanctioned because `clock` is a constitution-mandated core dependency that was simply never promoted from transitive; this feature is its first legitimate use.

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Domain | None | — |
| Data | None | — |
| Presentation | `_IntakeType` enum, `_CourseCard` widget, inline `SegmentedButton` section, new state (`_intakeType`, `_durationController`, `_pauseController`, `_startDate`), `_pickStartDate()`, info-chip computation, `build` wiring | `lib/features/meds/presentation/widgets/add_medication_modal.dart` (Modify) |
| L10n (source) | 9 new `medsAdd*` keys incl. first placeholder + ICU-plural message | `lib/l10n/app_en.arb`, `app_uk.arb`, `app_de.arb` (Modify) |
| L10n (generated) | Regenerated localization classes | `lib/l10n/app_localizations*.dart` (Generated) |
| Infra | Promote `clock` transitive → direct dependency | `pubspec.yaml` (Modify) |
| Tests | Widget tests for AC-3…AC-10 incl. `withClock` + uk-plural assertions | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` (Modify) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Default start date source | `DateUtils.dateOnly(clock.now())`; add `clock` as a direct dep | Honors approved "today, testable" choice; satisfies §8; `clock` is already transitive so zero resolution risk; `dateOnly` drops the time component | `DateTime.now()` (violates §8, non-deterministic tests); fixed seed constant like spec 029's `_defaultPickerTime` (bad UX for a real start date) |
| Day-count pluralization | Single ICU-plural message `medsAddCourseRangeLabel` with mixed placeholders `{range}` (String) + `{count}` (int, plural) | Keeps locale-correct word order in one string; gen-l10n supports mixed placeholder + plural; uk needs `one/few/many/other` | Two keys composed in Dart (`"Course: {range}"` + `"{count} days"`) — fragile word order, kept only as fallback if gen-l10n rejects the mixed message |
| Course end date | `end = _startDate.add(Duration(days: n - 1))` (inclusive) | Matches HTML "Mar 26 + 7 days → Apr 1"; simple, no calendar library | `n` days (off-by-one vs design); date-package interval math (overkill, DST out of scope) |
| Card reveal | Plain `if (_intakeType == _IntakeType.course) ...[ SizedBox, _CourseCard ]` spread | Mirrors spec 028 conditional fields; guarantees absent-from-tree for AC-3/AC-5; no controller needed | `AnimatedSize` wrapper (extra complexity; spec marks animation out of scope) |
| Intake-type representation | Private `enum _IntakeType { continuous, course }` in the same library | Type-safe segmented value (strict lint, no magic strings); not persisted so no domain enum needed | Domain `IntakeType` value object (out of scope — no persistence this iteration); `bool isCourse` (less readable, no third state headroom) |
| Date display format | `MaterialLocalizations.of(context).formatMediumDate(date)` | Locale-aware, no new `intl`/`DateFormat` dependency; consistent with spec 029's `formatTimeOfDay` | `intl` `DateFormat.yMMMd(locale)` (adds first direct `DateFormat` usage; pixel-matching HTML's compact `26 бер` is out of scope) |
| Duration live update | `TextField(onChanged: (_) => setState(() {}))` on the duration field; info chip reads controllers in `build` | Cheapest way to recompute the chip on edit; single-field rebuild | `ValueListenableBuilder`/`addListener` (more wiring for no benefit at this scale) |
| Start-date field widget | Tappable `InputDecorator(isEmpty: false, decoration: InputDecoration(labelText:…, suffixIcon: calendarDays))` wrapping the formatted date `Text` | Matches the outlined floating-label frame used by `_QuantityStepper`; read-only display + tap-to-pick | Read-only `TextField` with a controller (needs a controller to dispose for display-only text — unnecessary state) |

### Info-chip computation (the one piece of logic)

```
final n = int.tryParse(_durationController.text.trim());
if (n != null && n >= 1) {
  final end = _startDate.add(Duration(days: n - 1));
  label = l10n.medsAddCourseRangeLabel(
    '${ml.formatMediumDate(_startDate)} — ${ml.formatMediumDate(end)}', n);
} else {
  label = l10n.medsAddCourseStartOnly(ml.formatMediumDate(_startDate));  // AC-10 fallback
}
// `ml` = MaterialLocalizations.of(context); Pause is NOT read here.
```

### l10n authoring (exact template-arb metadata)

In `app_en.arb` (template), the two non-trivial keys carry `@`-metadata declaring placeholders (the file's first):

```json
"medsAddCourseRangeLabel": "Course: {range} ({count, plural, =1{1 day} other{{count} days}})",
"@medsAddCourseRangeLabel": {
  "description": "Course info chip: localized date range plus a pluralized day count.",
  "placeholders": {
    "range": { "type": "String" },
    "count": { "type": "int" }
  }
},
"medsAddCourseStartOnly": "Course starts {date}",
"@medsAddCourseStartOnly": {
  "description": "Course info-chip fallback shown when the duration is empty or not a positive integer.",
  "placeholders": { "date": { "type": "String" } }
}
```

- `app_uk.arb`: `count` plural needs `one`/`few`/`many`/`other` (e.g. `one{{count} день} few{{count} дні} many{{count} днів} other{{count} дня}`); `@`-metadata lives only in the template, not in uk/de.
- `app_de.arb`: `=1{1 Tag} other{{count} Tage}`.
- The other 7 keys are plain strings (no placeholders).

### Testability keys (ValueKeys to add)

Mirror the existing `ValueKey` convention (`'medsAddDoseField'`, `'medsAddQtyValue'`, …) so tests target widgets unambiguously behind the localized tree:
`'medsAddIntakeTypeSegmented'`, `'medsAddCourseCard'`, `'medsAddCourseDuration'`, `'medsAddCoursePause'`, `'medsAddCourseStartField'`, `'medsAddCourseInfoChip'`.

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Modify | Add `enum _IntakeType`; `_CourseCard` widget; inline segmented-button section; state fields + 2 controllers (disposed); `_pickStartDate()`; info-chip computation; `build` wiring after `_TimeChips`, before Save; `import 'package:clock/clock.dart';` |
| `lib/l10n/app_en.arb` | Modify | 9 new keys (2 with placeholder/plural `@`-metadata) |
| `lib/l10n/app_uk.arb` | Modify | 9 new keys; uk plural categories |
| `lib/l10n/app_de.arb` | Modify | 9 new keys; de plural categories |
| `lib/l10n/app_localizations*.dart` | Generated | Regenerated by `flutter gen-l10n` (3 files: base + en/uk/de) — not hand-edited |
| `pubspec.yaml` | Modify | Add `clock: ^1.1.x` to `dependencies` (promote transitive → direct; pin to the version `flutter pub deps` reports) |
| `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Modify | New widget tests for AC-3…AC-10, incl. `withClock(Clock.fixed(...))` for AC-7 and a uk-plural assertion (1/2/5 days) for AC-11 |

### Documentation Impact

No documentation changes expected — this is a visual-only presentation iteration with no persisted behavior, no new public API, and no architecture change. (`docs/features/*` for the add-medication flow remains accurate until the data-save iteration wires persistence.)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| gen-l10n rejects mixed `{range}` String + `{count}` plural in one message | Low | Med | Verified syntax is supported; `/execute-task` runs `flutter gen-l10n` and dart analyze; fallback = split into `medsAddCourseRangePrefix` + a `{count}` plural key composed in Dart |
| Ukrainian plural categories authored incorrectly | Med | Med | Use CLDR `one/few/many/other`; add a uk widget test asserting "1 день / 2 дні / 5 днів" |
| `withClock` not affecting the State field initializer | Low | Med | `_startDate = clock.now()` runs during `pumpWidget` inside the `withClock` zone; test wraps `pumpWidget` (not just setup) in `withClock` |
| Adding `clock` shifts other resolved versions | Low | Low | `clock` is already in `pubspec.lock` transitively; promotion to direct keeps the same resolved version (verify `flutter pub get` reports no downgrades) |
| `clock.now()` time component leaking into the date | Low | Low | Normalize with `DateUtils.dateOnly(...)` at assignment and after picking |
| Duration `onChanged: setState` causing focus loss | Low | Low | `setState` rebuilds the subtree but keeps focus on the `TextField`; verified pattern — acceptable for one field |

## Dependencies

- **New direct dependency**: `clock` (promote existing transitive dependency to a direct entry in `pubspec.yaml`; run `flutter pub get`). No other packages.
- No services, env vars, or native config.

## AC Coverage Check (Phase 2.5)

| AC | Covered by |
|----|-----------|
| AC-1 (section placement) | `build` wiring after `_TimeChips`, before Save (File Impact) |
| AC-2 (two-segment button) | Inline `SegmentedButton<_IntakeType>` (Layer Map, theme_selector pattern) |
| AC-3 / AC-5 (Continuous default, card absent/removed) | `_intakeType` default + conditional spread (Key Design Decisions) |
| AC-4 (Course reveals card) | Conditional `_CourseCard` render |
| AC-6 (card contents + defaults 7/0) | `_CourseCard` widget; controllers seeded `'7'`/`'0'` |
| AC-7 (start = today, testable) | `clock.now()` + `withClock` test; ValueKey on start field |
| AC-8 (date picker updates) | `_pickStartDate()` await/`mounted`/`setState` |
| AC-9 (live range + plural) | Info-chip computation + `medsAddCourseRangeLabel` |
| AC-10 (invalid-duration fallback) | `int.tryParse` null/`<1` → `medsAddCourseStartOnly` |
| AC-11 (3 arbs, uk plural, no hardcoded) | l10n authoring section + uk-plural test |
| AC-12 (controllers disposed) | `dispose()` additions |
| AC-13 (no-op Save, no domain/data) | Layer Map = presentation only; pubspec note is infra, not domain/data |
| AC-14 (analyze clean, tests pass, new tests) | `/execute-task` post-checks + new test file additions |

**Reverse check**: the plan introduces two files not in the spec's Affected-Areas table — `pubspec.yaml` (the `clock` promotion the spec calls out in §2/§7 but didn't tabulate) and is otherwise aligned. `pubspec.yaml` is flagged here as a planning-discovered addition.

## Supporting Documents

None — no external research, data model, or API contracts are needed for this presentation-only feature.
