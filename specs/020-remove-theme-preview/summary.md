## Feature Summary: 020 — Remove theme_preview feature

### What was built
Removed the dev-only `theme_preview` screen and every hook that reached it — the
`/theme-preview` route, the "Theme preview" button on the home screen, and the
tests that exercised them. This was disposable scaffolding for validating the
Material 3 design system during early development; deleting it closes **Bug 009**
(a Constitution §2.1 cross-feature import violation) by removing the offending
file rather than reworking it.

### Changes
- Task 001: Remove all source references — stripped the `/theme-preview` route + import + dartdoc from `app_router.dart`, removed the dev button from `home_screen.dart` (body now `const Center(child: Text('Hello World'))`), and updated the `app.dart` library dartdoc.
- Task 002: Update tests — dropped the "Theme preview" assertion from the home-render test, deleted the navigation/theme-cycle widget test, removed Test 5 (AC-13) and the `ThemePreviewScreen` import from the routing test, and cleaned up now-dead fake-repository getters.
- Task 003: Delete the feature folder + close Bug 009 — deleted `lib/features/theme_preview/` (3 files) and marked the bug Fixed with a resolution note. Ran the full `flutter test` + `build apk` gate.

### Files changed
- `lib/features/theme_preview/` — 3 files deleted (388 lines of widget code)
- `lib/core/routing/`, `lib/features/home/`, `lib/` — 3 files modified (route, button, dartdoc)
- `test/` — 2 files modified (tests removed/trimmed)
- `bugs/` — 1 file modified (Bug 009 → Fixed)

Total: 9 files changed, 24 insertions(+), 515 deletions(-)

### Key decisions
- Delete vs rework: chose deletion (research Option A) — the screen's M3-validation purpose was done; reworking (a local `ValueNotifier`) would leave dead-ish code.
- Task ordering: references-first, delete-folder-last so `dart analyze` stays green after every task (an orphaned-but-present library is not an analyze error).
- `HomeScreen` body simplified to `const Center(child: Text('Hello World'))` (KISS — a single-child Column is a pointless wrapper); `go_router` import retained for `/settings`.
- Docs cleanup deferred to `/finalize`'s tech-writer pass (spec §6); the plan's Documentation Impact table is the checklist.

### Deviations from plan
- Task 002: code review surfaced a §3 dead-code issue not in the original plan — the deleted theme-cycle test was the sole consumer of four `_FakeSettingsRepository` recording getters, which `dart analyze` does not flag (unused private-class members). Removed in a repair round.

### Acceptance criteria
- [x] AC-1: `lib/features/theme_preview/` deleted
- [x] AC-2: no `theme_preview` import path in `lib/` or `test/`
- [x] AC-3: `app_router.dart` has no `/theme-preview` route/import/TODO; route table = shell + `/settings` + errorBuilder
- [x] AC-4: `HomeScreen` body renders only "Hello World"; `go_router` import retained
- [x] AC-5: `app.dart` dartdoc drops `/theme-preview`; no code change
- [x] AC-6: `widget_test.dart` test 1 cleaned, test 2 deleted
- [x] AC-7: `app_router_test.dart` import + Test 5 + header comment removed
- [x] AC-8: Bug 009 marked Fixed with resolution note
- [x] AC-9: `dart analyze` reports zero diagnostics
- [x] AC-10: `flutter test` passes (226 tests)
- [x] AC-11: `flutter build apk --debug` succeeds
- [x] AC-12: no `print`/`debugPrint`/`!`/`dynamic` introduced
