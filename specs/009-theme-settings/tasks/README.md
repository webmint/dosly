# Tasks: Theme Settings

**Spec**: specs/009-theme-settings/spec.md
**Plan**: specs/009-theme-settings/plan.md
**Generated**: 2026-04-25
**Total tasks**: 7

## Dependency Graph

```
001 (deps + core infra) ──→ 002 (domain) ──→ 003 (data) ──→ 004 (provider + app wiring) ──→ 005 (l10n + UI) ──→ 007 (tests)
                                                                       │                          │
                                                                       └──→ 006 (retire ctrl + fix tests) ──→ 007
```

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Add dependencies and core infrastructure | architect | None | Complete |
| 002 | Create settings domain layer | architect | 001 | Complete |
| 003 | Create settings data layer | architect | 002 | Complete |
| 004 | Create settings provider and wire app root | architect | 003 | Complete |
| 005 | Add localization keys and build Settings UI | mobile-engineer | 004 | Complete |
| 006 | Retire ThemeController and fix all tests | architect | 004, 005 | Complete |
| 007 | Write settings feature tests | qa-engineer | 005, 006 | Complete |

## Additions to Spec

Files discovered during planning not in the original spec's Affected Areas:

| File | Reason |
|------|--------|
| `lib/core/error/failures.dart` | Core `Failure` sealed class — first data-layer feature requires it |
| `lib/core/providers/shared_preferences_provider.dart` | DI entry point for SharedPreferences |
| `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | Imports `theme_controller.dart` — must update when retiring it |
| `lib/core/routing/app_router.dart` | Doc comment references `themeController` — needs update |
| `test/widget_test.dart` | Uses `themeController` singleton — must rewrite |
| `test/core/routing/app_router_test.dart` | Needs `ProviderScope` wrapper after screens become ConsumerWidgets |
| `pubspec.yaml` additions | `flutter_riverpod` and `fpdart` — not just `shared_preferences` |

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Mechanical: add packages, create 2 small files |
| 002 | Low | Two small files, no dependencies on existing code |
| 003 | Low | Straightforward repo impl pattern |
| 004 | Medium | Rewrites `main.dart` and `app.dart` — first ProviderScope integration. Theme flash if wired wrong. |
| 005 | Low | Presentation work following M3 patterns |
| 006 | Medium | Touches 7 files, deletes 2, modifies 5 tests. Most likely place for regressions. |
| 007 | Low | Test-only, no production code changes |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 005 | Layer boundary crossing | Verify provider chain works: `main.dart` → `ProviderScope` → `settingsProvider` → `app.dart` reads themeMode correctly. `dart analyze` clean on tasks 001-004. |
| 006 | Convergence (depends on 004+005) + high-blast-radius | Verify Settings screen renders with Appearance section and SegmentedButton. ARB keys present in all 3 languages. ThemeSelector responds to taps. |

## AC Coverage

| AC | Tasks |
|----|-------|
| AC-1 (subheader) | 005 |
| AC-2 (SegmentedButton) | 005 |
| AC-3 (default System) | 002, 005 |
| AC-4 (immediate theme switch) | 004 |
| AC-5 (persistence survives restart) | 003, 004 |
| AC-6 (single source of truth model) | 002 |
| AC-7 (Clean Architecture boundaries) | 001, 002, 003, 004 |
| AC-8 (localization in 3 languages) | 005 |
| AC-9 (dart analyze) | 006 (full pass) |
| AC-10 (flutter test) | 006, 007 |
| AC-11 (flutter build) | 006 |
