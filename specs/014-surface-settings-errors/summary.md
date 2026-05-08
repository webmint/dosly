# Feature Summary: 014 — Surface Settings Persistence Errors

### What was built

Settings preference toggles (theme, system-theme, language, system-language) used to fail silently if `SharedPreferences` couldn't write — the toggle would visually revert with no user feedback. Now, every persistence failure surfaces as a localized M3 floating SnackBar ("Couldn't save your preference. Please try again." in en/de/uk). Closes bug 003 and establishes the side-channel `StreamProvider<Failure>` pattern as the project's canonical way to surface mutator failures to the UI without changing state shape.

### Changes

- **Task 001**: Added `settingsPersistenceError` ARB key in en/de/uk; `flutter gen-l10n` regenerated the four `app_localizations*.dart` files.
- **Task 002**: `SettingsNotifier` gained a broadcast `StreamController<Failure>` initialized in `build()` with `ref.onDispose` cleanup; all 4 mutator Left fold-branches now emit; new top-level `settingsErrorsProvider` (`StreamProvider<Failure>`); 6 unit tests added.
- **Task 003**: `SettingsScreen` converted from `StatelessWidget` to `ConsumerWidget`; new `ref.listen<AsyncValue<Failure>>` block shows a floating SnackBar via `ScaffoldMessenger`; widget test added (richer `_FakeSettingsRepository` with `failOnSaveX` flags); full integration gate green (203/203 tests, debug APK builds).
- **Task 004**: Front-matter flip on bug 003 (`Open` → `Closed`, `Fixed: 2026-05-07 (spec 014)`); `docs/features/settings.md` updated to describe the new error-stream + SnackBar contract; one-paragraph note added to `docs/architecture.md` documenting the pattern for future feature reuse.

### Files changed

- `lib/features/settings/presentation/providers/` — 1 file modified (+55/-x lines)
- `lib/features/settings/presentation/screens/` — 1 file modified
- `lib/l10n/` — 3 ARB files modified, 4 generated `app_localizations*.dart` regenerated
- `test/features/settings/presentation/` — 2 test files modified (provider + screen)
- `bugs/` — 1 file (front-matter flip)
- `docs/` — 2 files (settings.md, architecture.md)

Total source/test/docs delta: 11 files modified, ~225 lines (excluding spec artifacts).
With spec artifacts (spec.md, plan.md, research.md, tasks/*, review.md, verify.md, summary.md): 27 files, +1769/-50 lines.

### Key decisions

- **Failure-surfacing architecture**: Side-channel `StreamProvider<Failure>` (Option B from bug 003) — chosen over `AsyncNotifier` (Option A) because initial load is sync and never fails; wrapping state in `AsyncValue` would force every consumer (`app.dart`, two selectors, theme preview) to `.when`-unwrap with no real benefit. Smallest blast radius — only the notifier and the screen change.
- **StreamController ownership**: Owned by `SettingsNotifier`, initialized as the FIRST statement of `build()`, closed via `ref.onDispose` — Riverpod 3.x canonical pattern (verified via Context7).
- **Listener placement**: `ConsumerWidget` + `ref.listen` in `build` — simpler than `ConsumerStatefulWidget + ref.listenManual`, both are documented official patterns.
- **SnackBar message strategy**: Generic localized text; no `failure.message` rendered — privacy-clean (no PHI risk) and i18n-friendly.

### Acceptance criteria

- [x] AC-1: Stream getter, broadcast controller, ref.onDispose
- [x] AC-2: setThemeMode failure emits
- [x] AC-3: Other 3 mutators emit
- [x] AC-4: Right path does NOT emit
- [x] AC-5: state-not-updated-on-failure preserved (existing tests unmodified)
- [x] AC-6: zero debugPrint/print/log
- [x] AC-7: zero "deferred to bug 003" prose
- [x] AC-8: ARB key in en/de/uk + gen-l10n clean
- [x] AC-9: SnackBar with localized text
- [x] AC-10: SnackBar floating + verbatim text
- [x] AC-11: ConsumerWidget; body unchanged
- [x] AC-12: dart analyze passes
- [x] AC-13: flutter test passes
- [x] AC-14: flutter build apk --debug passes
- [x] AC-15: bug 003 front matter Closed
- [x] AC-16: docs/features/settings.md updated
