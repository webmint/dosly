# Feature Summary: 006 — Multi-Language Support (English, German, Ukrainian)

### What was built

dosly now renders its user-facing chrome in English, German, or Ukrainian, auto-detected from the device locale on every launch. The feature ships Flutter's official `flutter_localizations` + `intl` + `gen_l10n` toolchain end-to-end: ARB translation sources, generated `AppLocalizations` class, wired delegates, and a custom `localeResolutionCallback` that pins English as the fallback for unsupported locales. A user-facing language picker is deliberately out of scope (lands with the future Settings feature).

### Changes

- **Task 001**: Created three ARB files (`app_en.arb` template, `app_de.arb`, `app_uk.arb`) with four translatable keys each (`settingsTooltip`, `bottomNavToday`, `bottomNavMeds`, `bottomNavHistory`) and `@key` metadata on the English template.
- **Task 002**: Added `flutter_localizations` + `intl` deps, enabled `generate: true`, wrote `l10n.yaml`, ran `flutter pub get` to generate `AppLocalizations` + three locale subclasses (committed to `lib/l10n/`).
- **Task 003**: Wired `AppLocalizations.localizationsDelegates` and `supportedLocales` into `MaterialApp.router` in `DoslyApp`, with a dartdoc sentence describing locale auto-resolution.
- **Task 004**: Localized the HomeScreen `Settings` IconButton tooltip via `AppLocalizations`; `'Dosly'`, `'Hello World'`, and `'Theme preview'` remain hard-coded (per spec §6).
- **Task 005**: Registered `AppLocalizations` delegates in the existing `home_bottom_nav_test.dart` harness so Task 006 could land without breaking pre-existing assertions.
- **Task 006**: Localized the three HomeBottomNav destination labels (Today/Meds/History); outer `const HomeBottomNav({super.key})` preserved; `const` pushed down to each `Icon` leaf.
- **Task 007**: Added `home_bottom_nav_l10n_test.dart` with three widget cases (de/uk/fr-fallback). Discovered Flutter's default resolution picks the alphabetically-first `supportedLocales` entry (`de`), not English; added `_resolveLocale` in `lib/app.dart` as `localeResolutionCallback` to force English fallback.

**Post-review security hardening** (between `/review` and `/verify`): pinned `intl: ^0.20.2` (was `any`); introduced `lib/l10n/l10n_extensions.dart` with a `BuildContext.l10n` getter that owns the single sanctioned `AppLocalizations.of(context)!` — call sites use `context.l10n.xxx` with zero `!`.

### Files changed

- `lib/l10n/` — 8 new files (3 ARB sources, 4 generated Dart files, 1 `BuildContext.l10n` extension)
- `lib/app.dart` — modified (delegates, supportedLocales, `localeResolutionCallback`, `_resolveLocale`)
- `lib/features/home/presentation/screens/home_screen.dart` — modified (Settings tooltip → `context.l10n`)
- `lib/features/home/presentation/widgets/home_bottom_nav.dart` — modified (3 labels → `context.l10n`)
- `test/features/home/presentation/widgets/home_bottom_nav_test.dart` — modified (harness registers delegates)
- `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` — new (3 locale-switching tests)
- `pubspec.yaml`, `pubspec.lock`, `l10n.yaml` — i18n infrastructure
- `specs/006-i18n-support/` — spec, plan, research, review, 7 task files, README, this summary
- `.claude/memory/MEMORY.md` — 6 new entries covering Flutter i18n pitfalls and review patterns

Total: **30 files changed, 1559 insertions, 21 deletions** across 19 WIP/checkpoint commits (to be squashed by `/finalize`).

### Key decisions

- **First-party Flutter toolchain (`flutter_localizations` + `intl` + `gen_l10n`)** over `easy_localization` — type-safe ARB codegen, aligns with project preference for Flutter primitives and constitution §3.5 (no magic strings).
- **`synthetic-package: false` implicit** (Flutter 3.41+ retired the flag entirely) — generated files committed under `lib/l10n/` so fresh clones/CI compile without requiring codegen first.
- **Custom `localeResolutionCallback`** instead of Flutter's default — `supportedLocales` is emitted alphabetically (`[de, en, uk]`), and Flutter's default falls back to the first entry, which would surface German to users on unsupported locales. Explicit callback pins fallback to English (AC-9).
- **`context.l10n` extension centralizing the sanctioned `!`** — exactly one `AppLocalizations.of(this)!` in the codebase (in `l10n_extensions.dart:25`); every consumer widget calls `context.l10n.xxx` with zero `!` at call sites.
- **`intl: ^0.20.2`** (pinned) over `intl: any` — tightened during `/review` security hardening; must track `flutter_localizations`' transitive pin on Flutter SDK upgrades.

### Deviations from plan

- **Task 002**: `l10n.yaml`'s `synthetic-package: false` line was removed mid-task. Plan (based on Context7 docs) specified the flag; Flutter 3.41+ now emits a deprecation warning for ANY value. Omitting the line produces exactly the desired behavior. Task file and plan risk section updated.
- **Task 007**: Scope expanded mid-task to also modify `lib/app.dart`. Tests surfaced that Flutter's default locale resolution picks the first alphabetical `supportedLocales` entry (`de`), not English. Fix required adding `_resolveLocale` + `localeResolutionCallback` to production. Spec §3.2 and AC-5 were updated to document the discovery.
- **`helloWorld` dropped from translation scope** (user decision during `/breakdown`) — reduced translatable keys from 5 to 4. HomeScreen's `'Hello World'` body placeholder stays hard-coded; it's a temporary scaffold slated for replacement when the real Today content ships (same rationale as the already-excluded `'Theme preview'`).
- **Post-review security hardening**: introduced `context.l10n` extension (not in the plan) to centralize the sanctioned `!` to exactly one site, addressing a Medium security finding about doc-drift with spec §7.

### Acceptance criteria

- [x] AC-1: pubspec has `flutter_localizations`, `intl: ^0.20.2`, `generate: true`
- [x] AC-2: `l10n.yaml` exists with correct keys
- [x] AC-3: three ARB files with 4 keys + `@key` metadata in en
- [x] AC-4: generated `AppLocalizations` importable with four getters
- [x] AC-5: `MaterialApp.router` wired with delegates + `localeResolutionCallback`
- [x] AC-6: HomeScreen Settings tooltip localized
- [x] AC-7: HomeBottomNav three labels localized; outer `const` preserved
- [x] AC-8: all pre-existing tests still pass (85 → baseline unchanged)
- [x] AC-9: new de/uk/fr-fallback widget tests (3 cases)
- [x] AC-10: `dart analyze` clean
- [x] AC-11: `flutter test` clean (88/88)
- [x] AC-12: `flutter build apk --debug` succeeds
- [ ] AC-13: Manual on-device verification (deferred to user post-merge per spec §5)
