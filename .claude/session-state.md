<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State

## Current Feature
006-i18n-support — **All 7 tasks complete**. Ready for `/review` → `/verify` → `/summarize` → `/finalize`.

## Recently Completed Tasks
- **Task 007** (qa-engineer): Added `home_bottom_nav_l10n_test.dart` with 3 cases (de/uk/fr-fallback). Discovered Flutter default falls back to alphabetically-first locale, not English. Fix: added `_resolveLocale` in `lib/app.dart` as `localeResolutionCallback`. Spec §3.2 and AC-5 updated.
- **Task 006** (mobile-engineer): Localized `HomeBottomNav` destination labels via `AppLocalizations.of(context)!.bottomNav{Today,Meds,History}`. `const` pushed down to Icon leaves.
- **Task 005** (qa-engineer): Registered delegates in `home_bottom_nav_test.dart` harness. `const` moved from outer MaterialApp to inner Scaffold.

## Recent Decisions
- **Dropped `synthetic-package: false`** from `l10n.yaml` — Flutter 3.41+ fully retired the option; omission = current default.
- **Added `localeResolutionCallback`** to `MaterialApp.router` — Flutter's default fallback picks first `supportedLocales` entry (alphabetically `de`), not English. Explicit callback pins fallback to English.
- **Dropped `helloWorld` from i18n scope** — it's a temporary placeholder on HomeScreen; translating wasted work.

## Recently Modified Files
- `lib/app.dart` — added `_resolveLocale` + wired `localeResolutionCallback`
- `lib/features/home/presentation/widgets/home_bottom_nav.dart` — localized labels
- `lib/features/home/presentation/screens/home_screen.dart` — localized Settings tooltip
- `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` — 4 keys each
- `lib/l10n/app_localizations*.dart` — generated, committed
- `pubspec.yaml`, `pubspec.lock`, `l10n.yaml` — infra for i18n
- `test/features/home/presentation/widgets/home_bottom_nav_test.dart` — delegates registered
- `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` — new locale tests

## Verification State
- `dart analyze`: clean
- `flutter test`: 88/88 pass (85 pre-existing + 3 new)
- `flutter build apk --debug`: success

## Context Load
light
