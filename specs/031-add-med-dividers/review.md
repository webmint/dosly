# Review Report: 031-add-med-dividers

**Date**: 2026-06-16
**Spec**: specs/031-add-med-dividers/spec.md
**Changed files**: 2
- `lib/features/meds/presentation/widgets/add_medication_modal.dart` (Task 001)
- `test/features/meds/presentation/widgets/add_medication_modal_test.dart` (Task 002)

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 2 — **PASS**

Presentation-only diff (layout restructure into 3 padded groups + 2 `Divider`s, 2 titles recolored to
`onSurfaceVariant`, a `_sectionDivider` style helper, 4 spacing-constant tweaks, a 24px bottom spacer,
3 widget-tree-assertion tests). No secrets, no network, no new dependencies, no PHI sink, no
debug artifacts, no constitution violations. Medication-data controllers (`_nameController`,
`_doseController`, `_stock*Controller`) are passed to children unchanged — no new leak path.

- **Info** — `add_medication_modal.dart` (Save button, `onPressed: () {}`): intentional, documented
  no-op for the visual iteration — not error-swallowing.
  Recommendation: when the data-save iteration wires this to drift, route medication name/dose/stock
  only through the PHI-sanitizing typed logger (never `print`/`debugPrint`), per constitution.
- **Info** — both files: no network/secret/file/deserialization/dynamic-exec introduced.
  Recommendation: none — forward-looking note only.

## Performance Review

- High: 0 | Medium: 0 | Low: 2

Purely additive static widget nesting; no animations/streams/listeners added (existing
`AnimatedSize`/`AnimatedRotation` untouched). The outer `Column` of 5 direct children under the
existing `SingleChildScrollView` is O(children) layout, sub-1ms. At most ~8 small short-lived heap
objects per `setState` rebuild — negligible, no frame-budget impact.

- **Low** — `add_medication_modal.dart:1370` & `:1401`: two inline `titleSmall?.copyWith(color: …)`
  allocations per build (one `TextStyle` each).
  Recommendation (DRY/readability, not a perf fix): extract a single
  `final sectionTitleStyle = textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant);`
  local after the existing `colorScheme`/`textTheme` locals and reuse it for both titles.
- **Low** — `add_medication_modal.dart:1253–1260` (`_sectionDivider`, called at `:1356`/`:1386`):
  allocates a new `Padding`+`Divider` per build.
  Recommendation: no action required. Element reconciliation reuses the render objects; cost is two
  pointer-sized objects per rebuild. (A future `const Divider` + `DividerTheme`-driven color could
  eliminate it, but that is optional.)

## Test Assessment

- AC items with automated test coverage: **2 of 12 fully** (AC-4, AC-11); AC-1 & AC-3 partial; 6 ACs
  (AC-2/5/7/8/9/10) legitimately visual-only; AC-6 & AC-12 uncovered-but-cheap.
- **Verdict: GAPS FOUND** (none blocking — the 3 new tests are correct and well-structured)

Coverage gaps (ranked by value/cost — report only):
- **AC-1 (medium)**: only the no-form baseline is tested. Untested: divider count `== 2` when a form
  is selected (Tablet → `_StockCard` expands Group A) and when Course is selected (`_CourseCard`
  expands Group C). A divider mistakenly placed inside a conditional block would regress to 3 and slip
  through. Cheap: tap Tablet / Course, then `expect(find.byType(Divider), findsNWidgets(2))`.
- **AC-3 (low)**: only `find.byType(Divider).first` is asserted; add the same thickness/color check on
  `.last` (2 lines, no new test).
- **AC-6 (low–medium)**: no test guards that `_StockCard`/`_CourseCard` headers stay `onSurface` (i.e.
  `style?.color == null`). Guards against a future edit accidentally muting card headers like the
  section titles. Needs Tablet/Course selected first (~12 lines each).
- **AC-12 (low)**: only implicitly guarded. Extending the existing `uk` locale test to assert the two
  section-title strings ('Час прийому', 'Тип прийому') would make the no-hardcoded-string guard
  explicit.
- **AC-2/5/7/8/9/10 (acceptable)**: pixel-exact spacing/padding constants — correctly left to visual /
  golden / code-read review for a visual-only iteration; not worth brittle geometry tests.

### Gap Closure (2026-06-16, post-review follow-up)

The AC-1, AC-3, and AC-6 gaps were closed by adding 5 tests to the `AddMedicationModal dividers`
group (test file 41 → 46; full suite 327 → 332, all green; `dart analyze` clean):
- AC-1: divider count stays 2 with a form (Tablet) selected AND with Course selected (both expanded states).
- AC-3: the second divider's `thickness`/`outlineVariant` is now asserted (not just the first).
- AC-6: `_StockCard` ('Pack stock') and `_CourseCard` ('Course parameters') headers asserted as
  unmodified `titleSmall` and explicitly `isNot(onSurfaceVariant)` — guards against accidental muting.

Remaining (intentionally not added): AC-12 explicit locale guard (low priority); AC-2/5/7/8/9/10
pixel-exact spacing (visual-only).
