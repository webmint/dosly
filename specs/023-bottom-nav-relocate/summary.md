## Feature Summary: 023 — Bottom Nav Relocate

### What was built
Resolved Bug 015 (constitution §2.1: `lib/core/` must be feature-agnostic). The app's bottom navigation widget — which hardcodes the Today/Meds/History feature destinations — was moved out of the generic `core/widgets/` folder into `core/routing/`, beside the app shell that composes the feature screens. No behavior, appearance, or API changed; this is a structural cleanup that restores `core/widgets/` to genuinely feature-agnostic.

### Changes
- Task 1: Relocate AppBottomNav from core/widgets to core/routing — moved the widget (verbatim) and its two widget tests, updated four import paths, leaving logic and rendering untouched.

### Files changed
- `lib/core/routing/` — 1 file moved in (`app_bottom_nav.dart`), 1 modified (`app_shell.dart` import)
- `test/core/routing/` — 2 test files moved in (`app_bottom_nav_test.dart`, `app_bottom_nav_l10n_test.dart`), 1 modified (`app_router_test.dart` import)
- [Total: 5 files changed, 4 insertions, 4 deletions — widget moved with zero content delta]

### Key decisions
- Placement: relocate to `core/routing/` (the existing composition root that already imports feature screens) rather than create a new `lib/app/` layer or parameterize the destinations list.
- L10n import: left `../../l10n/l10n_extensions.dart` unchanged — `core/routing/` and `core/widgets/` are the same depth.
- Scope: behavior-preserving move only; the pre-existing redundant `Column` wrapper (perf review, Low) was deliberately left alone as out of scope.

### Acceptance criteria
- [x] AC-1: widget exists at new path; old path removed
- [x] AC-2: public API unchanged (class + two required params)
- [x] AC-3: renders identically (NavigationBar + 1-px Divider, three destinations, same icons/l10n keys, labelBehavior alwaysShow)
- [x] AC-4: `app_shell.dart` imports new location and constructs identically
- [x] AC-5: all three test files import the new package path; both widget tests under `test/core/routing/`
- [x] AC-6: `dart analyze` clean
- [x] AC-7: full suite passes unchanged (241 tests)
- [x] AC-8: `core/widgets/` holds no feature-aware widget
