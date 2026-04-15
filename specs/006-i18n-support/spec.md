# Spec: Multi-Language Support (English, German, Ukrainian)

**Date**: 2026-04-14
**Status**: Complete
**Author**: Claude + Mykola

## 1. Overview

Introduce internationalization (i18n) infrastructure to dosly using Flutter's official `flutter_localizations` + `intl` toolchain with ARB files and `flutter gen-l10n` codegen. Support three locales — English (`en`, default fallback), German (`de`), and Ukrainian (`uk`) — and translate every user-facing string currently rendered in the running app, except (a) the brand name "Dosly", (b) the dev-only Theme Preview screen scheduled for post-MVP removal, and (c) the temporary `'Hello World'` placeholder body label on HomeScreen (scheduled for replacement when the real Today content ships — translating a placeholder is wasted work that gets deleted). The active locale is auto-detected from the device locale on every launch; a user-facing language switcher is explicitly out of scope (lands later with the Settings feature).

## 2. Current State

dosly has **zero localization infrastructure**. There is no `flutter_localizations` dependency, no `l10n.yaml`, no ARB files, no generated `AppLocalizations` class, and no `localizationsDelegates` / `supportedLocales` configuration on `MaterialApp.router` in `lib/app.dart:26-32`. Every user-facing string in the app is a hard-coded English literal in widget `build()` methods.

### Currently rendered translatable strings

The only screens reachable in the running app are `HomeScreen` (route `/`) and `ThemePreviewScreen` (route `/theme-preview`, dev-only, scheduled for post-MVP removal per `specs/002-main-screen/spec.md` §6 and §8 — see also the `TODO(post-mvp)` at `lib/features/home/presentation/screens/home_screen.dart:59`).

| Location | Line | String | Translate? |
|---|---|---|---|
| `lib/features/home/presentation/screens/home_screen.dart` | 40 | `'Dosly'` (AppBar title) | **No** — brand name |
| `lib/features/home/presentation/screens/home_screen.dart` | 45 | `'Settings'` (IconButton tooltip) | **Yes** |
| `lib/features/home/presentation/screens/home_screen.dart` | 57 | `'Hello World'` (placeholder body label) | **No** — temporary placeholder, scheduled for replacement when the real Today content lands (same rationale as `'Theme preview'` below) |
| `lib/features/home/presentation/screens/home_screen.dart` | 64 | `'Theme preview'` (OutlinedButton label) | **No** — dev scaffolding, scheduled for removal |
| `lib/features/home/presentation/widgets/home_bottom_nav.dart` | 51 | `'Today'` | **Yes** |
| `lib/features/home/presentation/widgets/home_bottom_nav.dart` | 55 | `'Meds'` | **Yes** |
| `lib/features/home/presentation/widgets/home_bottom_nav.dart` | 59 | `'History'` | **Yes** |
| `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | 32 | `'dosly · M3 preview'` (AppBar title) | **No** — dev-only, removal pending |
| `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | 35 | `'Cycle theme mode'` (tooltip) | **No** — dev-only, removal pending |
| `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | 47 | `'Demo FAB'` (tooltip) | **No** — dev-only, removal pending |
| `lib/app.dart` | 27 | `'dosly'` (`MaterialApp.title`) | **No** — brand name; also drives Android task switcher label |

**Total translatable**: 4 strings (`Settings`, `Today`, `Meds`, `History`).

### Existing app-wide-state pattern (precedent for locale handling)

Per `docs/architecture.md:45-85` and `lib/core/theme/theme_controller.dart`, the only pre-existing piece of app-wide reactive state is `themeController` — a top-level `final ValueNotifier<ThemeMode>` that:

- lives at `lib/core/theme/theme_controller.dart`
- is consumed by `DoslyApp` (in `lib/app.dart:24-35`) via `ListenableBuilder`
- is **in-memory only** — explicitly resets to `ThemeMode.system` on every restart; persistence is deferred to the future Settings feature

This i18n feature **does not introduce a parallel `localeController`**. There is no UI control to switch the locale in this feature, so reactive state would have nothing to drive. The active locale is whatever Flutter resolves from the device locale at framework-bind time, which is already reactive to OS-level locale changes for free via `MaterialApp`'s built-in handling.

When the future Settings feature lands, *both* the language picker and its persistence (and the corresponding `localeController`) ship together as one coherent unit, mirroring how `themeController` will gain its persistence.

### Existing tests pinning English literals

| Test file | Lines | What pins English |
|---|---|---|
| `test/features/home/presentation/widgets/home_bottom_nav_test.dart` | 31, 32, 33, 60, 66 | `find.text('Today' \| 'Meds' \| 'History')` and `tester.tap(find.text(...))` |

All 84 existing tests pass today. After this feature, these existing assertions must continue to pass when the test harness pumps the widget under the English (default) locale.

### Constitution constraints relevant to this feature

- **§2.1 Layer Boundaries**: i18n strings + `AppLocalizations` are presentation concerns. They MUST NOT be imported into any `domain/` directory. (Currently moot — no `domain/` exists yet.)
- **§2.3 Dependency Rules**: New packages added via `flutter pub add`, never by manual `pubspec.yaml` edits. `flutter_localizations` ships with the Flutter SDK; `intl` is a published package — both are first-party, allowlist-clean.
- **§3.5 No magic strings**: localized strings live in ARB files keyed by symbolic identifiers. Widgets call `AppLocalizations.of(context)!.todayLabel` (or equivalent), not raw strings.
- **§4.1.1**: `const` constructors preferred. Localized strings are read at runtime via `BuildContext`, so widgets that read them cannot be `const`. This is unavoidable and accepted; the const-ness loss is limited to widgets that actually display a translated string (i.e. `HomeBottomNav` becomes non-const at the destinations level — see §7 below).

## 3. Desired Behavior

### 3.1 Setup

- `flutter_localizations` (SDK) and `intl` (pub) are added to `pubspec.yaml` via `flutter pub add`.
- `l10n.yaml` is created at the repo root configuring `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, and `output-class: AppLocalizations`. Generated files live under `.dart_tool/flutter_gen/gen_l10n/` (untracked) and are imported via `package:flutter_gen/gen_l10n/app_localizations.dart` per Flutter's standard gen-l10n setup.
- `pubspec.yaml`'s `flutter:` section gains `generate: true` (required for gen-l10n).
- Three ARB source files exist under `lib/l10n/`:
  - `app_en.arb` — English (template, default fallback)
  - `app_de.arb` — German
  - `app_uk.arb` — Ukrainian
- All four translatable strings have a key in all three ARB files. Each key has a `@key` metadata entry in `app_en.arb` describing the string's purpose and surface (e.g., "Bottom navigation bar destination label — opens the Today tab").

### 3.2 App wiring

`DoslyApp` (in `lib/app.dart`) configures the `MaterialApp.router` with:

- `localizationsDelegates: AppLocalizations.localizationsDelegates` (which already includes the three Material/Cupertino/Widgets delegates)
- `supportedLocales: AppLocalizations.supportedLocales`
- No explicit `locale:` parameter — the device locale drives resolution.
- An explicit `localeResolutionCallback: _resolveLocale` that matches the device locale's `languageCode` against `supportedLocales` and falls back to `Locale('en')` when no match is found. **This is not Flutter's default behavior.** Discovered during Task 007 implementation: `flutter gen-l10n` emits `supportedLocales` alphabetically by locale code (`de, en, uk`), and Flutter's default `BasicLocaleListResolutionCallback` falls back to the FIRST entry of `supportedLocales` — which would be German, not English. The custom callback pins the fallback to English regardless of list order, satisfying AC-9 and the intended UX described below.
  - If the device locale matches `de` or `uk`, those translations render.
  - Otherwise (English or any other unsupported locale), the app falls back to English.

`MaterialApp.title` stays `'dosly'` (brand name; per Flutter docs `onGenerateTitle` is the localized variant, but since the app name is intentionally not translated, the static `title` remains).

### 3.3 String translations

| Key | English (default) | German | Ukrainian |
|---|---|---|---|
| `settingsTooltip` | `Settings` | `Einstellungen` | `Налаштування` |
| `bottomNavToday` | `Today` | `Heute` | `Сьогодні` |
| `bottomNavMeds` | `Meds` | `Medikamente` | `Ліки` |
| `bottomNavHistory` | `History` | `Verlauf` | `Історія` |

Translations are correct, idiomatic, and contextually appropriate for a medication-tracking app. The user is fluent in Ukrainian and will sanity-check `app_uk.arb` during review; German translations will be accepted as-provided unless the user flags an issue.

### 3.4 Widget changes

Widgets that previously rendered hard-coded English literals now read from `AppLocalizations.of(context)!`:

- `HomeScreen` (`lib/features/home/presentation/screens/home_screen.dart`):
  - `Settings` tooltip → `AppLocalizations.of(context)!.settingsTooltip`
  - `Dosly` AppBar title, `Hello World` body placeholder, and `Theme preview` button label remain hard-coded literals (per §1).
- `HomeBottomNav` (`lib/features/home/presentation/widgets/home_bottom_nav.dart`):
  - The three `NavigationDestination` `label:` arguments now read from `AppLocalizations.of(context)!.bottomNav{Today,Meds,History}`.
  - The widget remains a `StatelessWidget`. The widget's `const` constructor stays (`const HomeBottomNav({super.key})`), but the `NavigationDestination` instances themselves are no longer `const` because their labels are runtime values from `BuildContext`. The top-level `_noop` and `Divider` constants remain as before.

### 3.5 Test changes

- `test/features/home/presentation/widgets/home_bottom_nav_test.dart`'s `_harness()` helper is updated to inject `AppLocalizations.localizationsDelegates` and `supportedLocales` on its `MaterialApp`, defaulting to the English locale (no `locale:` override needed — `MaterialApp` resolves to `en` in the absence of a device locale during widget tests).
- All existing `find.text('Today' | 'Meds' | 'History')` assertions continue to pass unchanged (English remains the default in tests).
- The harness must continue to satisfy the existing `const`-at-call-site invariant for everything except the `MaterialApp` itself (which becomes non-const because `localizationsDelegates` is a runtime list).
- New tests are added — see AC-9 below.

## 4. Affected Areas

| Area | Files | Impact |
|---|---|---|
| Dependencies | `pubspec.yaml` | Add `flutter_localizations` (sdk) and `intl` (pub) under `dependencies:`. Add `flutter: { generate: true }` flag. |
| i18n config | `l10n.yaml` (repo root) | Create new — gen-l10n configuration |
| Translation source | `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb` | Create new — 4 keys × 3 languages with `@key` metadata in `app_en.arb` |
| App root | `lib/app.dart` | Wire `localizationsDelegates` + `supportedLocales` into `MaterialApp.router` |
| Home screen | `lib/features/home/presentation/screens/home_screen.dart` | Replace `'Settings'` literal with `AppLocalizations.of(context)!.settingsTooltip`. `'Hello World'` body placeholder stays hard-coded (temporary — will be replaced wholesale when the real Today content ships). |
| Home bottom nav | `lib/features/home/presentation/widgets/home_bottom_nav.dart` | Replace three destination labels with `AppLocalizations.of(context)!` lookups; drop `const` from inner `NavigationDestination`s and the destinations list |
| Existing widget tests | `test/features/home/presentation/widgets/home_bottom_nav_test.dart` | Inject `AppLocalizations` delegates into `_harness()`; existing English assertions stay unchanged |
| New tests | `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` (or extend existing file) | Pump under `de` and `uk` locales; assert translated labels render. See AC-9. |
| Generated code | `.dart_tool/flutter_gen/gen_l10n/app_localizations*.dart` | Auto-generated by `flutter gen-l10n` (runs implicitly on `flutter pub get` / `flutter run` when `generate: true`). NOT committed — `.dart_tool/` is gitignored. |
| Documentation | `docs/architecture.md`, `docs/features/home.md`, possibly new `docs/features/i18n.md` | Updated by `tech-writer` during `/finalize`, NOT in this spec's scope. |

## 5. Acceptance Criteria

- [x] **AC-1**: `pubspec.yaml` has `flutter_localizations: { sdk: flutter }` and `intl: ^<latest-stable-compatible-with-sdk-^3.11.1>` under `dependencies:`, added via `flutter pub add`. The `flutter:` section has `generate: true`.
- [x] **AC-2**: `l10n.yaml` exists at the repo root with `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `output-class: AppLocalizations`.
- [x] **AC-3**: Three ARB files exist at `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb`. Each contains the four keys `settingsTooltip`, `bottomNavToday`, `bottomNavMeds`, `bottomNavHistory`. `app_en.arb` includes `@key` metadata for each key with a one-sentence description of where the string is used. `app_de.arb` and `app_uk.arb` do not need `@key` blocks.
- [x] **AC-4**: After running `flutter pub get`, `flutter gen-l10n` (or implicit codegen) produces a generated `AppLocalizations` class importable via `package:dosly/l10n/app_localizations.dart`, with getters for all four keys. (Import path follows the plan's `synthetic-package: false` decision — see [plan.md](plan.md).)
- [x] **AC-5**: `lib/app.dart`'s `MaterialApp.router` is configured with `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales: AppLocalizations.supportedLocales`, and a `localeResolutionCallback` (added during Task 007 to force English fallback regardless of alphabetical `supportedLocales` ordering — see §3.2 for rationale). No explicit `locale:` is set. `MaterialApp.title` remains `'dosly'`.
- [x] **AC-6**: `lib/features/home/presentation/screens/home_screen.dart` no longer contains the hard-coded literal `'Settings'` as the IconButton tooltip — it now resolves through `AppLocalizations.of(context)!.settingsTooltip`. The `'Dosly'` AppBar title, `'Hello World'` body placeholder, and `'Theme preview'` button label remain hard-coded literals.
- [x] **AC-7**: `lib/features/home/presentation/widgets/home_bottom_nav.dart` no longer contains the hard-coded literals `'Today'`, `'Meds'`, `'History'` — all three resolve through `AppLocalizations.of(context)!`. The widget's outer `const HomeBottomNav({super.key})` constructor is preserved. The top-level `_noop` function and the `Divider(height: 1, thickness: 1)` constant are preserved.
- [x] **AC-8**: All existing tests in `test/` continue to pass. In particular, `test/features/home/presentation/widgets/home_bottom_nav_test.dart`'s English-text assertions (`find.text('Today' | 'Meds' | 'History')`) still pass after the harness is updated to register `AppLocalizations` delegates.
- [x] **AC-9**: A new widget test file (or new test cases in the existing file) exercises locale switching for `HomeBottomNav`:
  - Pumps the widget under `Locale('de')` → asserts `find.text('Heute')`, `find.text('Medikamente')`, `find.text('Verlauf')` each find one widget.
  - Pumps the widget under `Locale('uk')` → asserts `find.text('Сьогодні')`, `find.text('Ліки')`, `find.text('Історія')` each find one widget.
  - Pumps the widget under `Locale('fr')` (unsupported) → asserts the English fallback strings render (`find.text('Today')`, etc.).
- [x] **AC-10**: `dart analyze` produces zero warnings or errors after the changes.
- [x] **AC-11**: `flutter test` runs cleanly with all tests passing (existing 84 + new locale tests, exact final count TBD).
- [x] **AC-12**: `flutter build apk --debug` succeeds.
- [x] **AC-13**: Manual on-device verification (deferred to user, post-merge): with device locale set to German, the bottom nav reads "Heute / Medikamente / Verlauf" and the Settings tooltip reads "Einstellungen". With device locale set to Ukrainian, the bottom nav reads "Сьогодні / Ліки / Історія" and the Settings tooltip reads "Налаштування". With device locale set to anything else (e.g., French, Japanese), it falls back to English.

## 6. Out of Scope

This spec adds infrastructure and translates currently-visible strings. The following are **explicitly NOT included**:

- **NOT included**: A user-facing language picker UI (anywhere — AppBar action, drawer, settings page, dev button). The only mechanism to change language in this feature is the device locale.
- **NOT included**: Persistence of a user-selected language. There is no user-selected language in this feature; every launch re-resolves from the device locale. Persistence will land with the future Settings feature alongside the picker.
- **NOT included**: A `localeController` parallel to `themeController`. Same reason — no UI to drive it.
- **NOT included**: Locale-aware date/number formatting (`intl`'s `DateFormat`, `NumberFormat`). The currently-rendered strings are static. When schedule / intake / adherence screens land, they will introduce locale-aware formatting in their own specs.
- **NOT included**: Translating `'Dosly'` (brand name). Stays English-spelled in all locales, including the AppBar title and `MaterialApp.title`.
- **NOT included**: Translating ANY string in `lib/features/theme_preview/` — that feature is scheduled for post-MVP deletion (see `lib/features/home/presentation/screens/home_screen.dart:59` TODO and `specs/002-main-screen/spec.md` §6 + §8). Adding translations there would be wasted work that gets deleted.
- **NOT included**: Translating the `'Theme preview'` button label on `HomeScreen` (line 64) — same reason as above; the button itself is scheduled for removal alongside the theme preview feature.
- **NOT included**: Translating the `'Hello World'` body placeholder on `HomeScreen` (line 57) — temporary placeholder; will be replaced wholesale when the real Today content ships. Translating a placeholder is wasted work that gets deleted, analogous to the `'Theme preview'` rationale.
- **NOT included**: Pluralization, gender, or `intl` ICU message syntax in ARB files. None of the five strings need them. Future strings that do will introduce ICU messages on demand.
- **NOT included**: Right-to-left (RTL) language support. Neither English, German, nor Ukrainian is RTL.
- **NOT included**: Notification text translation (constitution §5.2 specifies notification text is "Time for your medication" — no medication name for privacy — but notifications are not implemented yet, so this is doubly out of scope).
- **NOT included**: Adding additional locales beyond `en`, `de`, `uk`. New locales = new spec.
- **NOT included**: Documentation updates (`docs/`). Per `CLAUDE.md`, doc updates are produced by `tech-writer` during `/finalize`, not as part of this spec.

## 7. Technical Constraints

- **MUST follow** Flutter's official `flutter_localizations` + `intl` + `flutter gen-l10n` flow (constitution §4.3 — "Existing patterns over new ones" + project preference for first-party Flutter primitives, mirroring the `ValueNotifier`-over-Riverpod choice for `themeController`).
- **MUST follow** constitution §2.3 for dependency additions: use `flutter pub add`, never edit `pubspec.yaml` manually for the dependency lines (the `flutter: { generate: true }` flag is a `pubspec.yaml` edit because `flutter pub add` cannot set it; this is an accepted exception documented in plan).
- **MUST NOT introduce** any `package:flutter/*` import into `domain/` directories (constitution §2.1, §4.2.1). Currently moot — no `domain/` exists. Reaffirmed for future-proofing: `AppLocalizations` is a presentation-layer concern and must never leak into domain or data.
- **MUST NOT use** `print()` / `debugPrint()` (constitution §4.2.1 / `avoid_print` lint).
- **MUST NOT use** `!` null-assertion operator anywhere except on `AppLocalizations.of(context)!`. Per Flutter's official gen-l10n pattern, `AppLocalizations.of(context)` returns nullable (`AppLocalizations?`) and the canonical pattern is `AppLocalizations.of(context)!`. This is a documented exception to the constitution's no-`!` rule, justified by: (a) the value is non-null whenever the app is correctly configured (delegates are registered in `MaterialApp`), (b) every Flutter sample and the Flutter team's official guidance uses this pattern, (c) the alternative (manually null-checking and showing a fallback) doubles the code at every call site for a condition that cannot occur in practice. **Implementation detail** (applied during `/review` security hardening): the `!` lives in **exactly one place** — `lib/l10n/l10n_extensions.dart`'s `BuildContext.l10n` getter. All consumer widgets call `context.l10n.xxx` (no `!` at the call site); the extension performs the null-assertion once on their behalf. This centralizes the sanctioned exception to a single auditable location.
- **MUST keep** `dart analyze` clean under the project's strict-mode `analysis_options.yaml` (constitution §3.1).
- **MUST NOT break** any of the 84 existing tests.
- **MUST handle** unsupported device locales by falling back to English (Flutter's default `localeResolutionCallback` already does this; no custom callback needed).
- **MUST commit** the ARB files and `l10n.yaml`. **MUST NOT commit** generated files under `.dart_tool/` (already gitignored).
- **SHOULD use** `@key` metadata in `app_en.arb` to give translators (and future maintainers) context for each string.

## 8. Open Questions

- **Q1**: Should the German translation `Medikamente` be shortened to `Meds` (or `Medi`) to match the English label's compactness in the bottom nav? `Medikamente` is ~12 characters and may overflow the `NavigationDestination` label slot at smaller phone widths. The user (or a German-speaking reviewer) should confirm during plan review whether `Medikamente` is acceptable or whether a shorter form (e.g., `Pillen`, `Medis`, `Medi`) is preferred. The same potential issue applies to `Einstellungen` for the future Settings tooltip, but tooltips have no width constraint, so it's only the nav labels at risk. **Suggested resolution**: Accept `Medikamente` for now; if AC-13 manual verification reveals truncation, file a follow-up to shorten it. (Not blocking.)
- **Q2**: When the future Settings feature ships and the user picks a non-device locale, should the app re-resolve to the *device* locale on next launch (i.e., the picker is "current session only") or persist the choice? This decision belongs to the Settings feature spec — flagged here only so it isn't lost.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| German `Medikamente` overflows the bottom nav label width on small devices | Medium | Low (visual only — text truncates with ellipsis, doesn't crash) | AC-13 manual verification on a small-screen device + Q1 resolution at plan time. If truncation is observed, follow-up spec shortens to `Medi` or similar. |
| `flutter pub add intl` pulls a version incompatible with Flutter SDK ^3.11.1 | Low | Medium (build break) | The plan task that adds the dep verifies the resolved version against `flutter pub deps`. If incompatible, pin to the version `flutter` itself depends on (`flutter pub deps | grep intl`). |
| Existing `home_bottom_nav_test.dart` harness fails after `MaterialApp` becomes non-const | Low | Low (test-only fix) | Update `_harness()` to drop `const` on the outer `MaterialApp`; inner `Scaffold` and `SizedBox.shrink()` stay `const`. |
| Ukrainian translations are subtly wrong (e.g., `Ліки` vs `Медикаменти` for "Meds") | Low | Low (user is fluent and reviews) | User reviews `app_uk.arb` during plan / spec review, can request changes before approval. |
| German translations are subtly wrong (no fluent reviewer in the loop) | Medium | Low (cosmetic; can be fixed in a follow-up) | Accept user's plan-time spot check; commit to fixing in a follow-up if a German-speaking user later reports an issue. Translations are easily editable in ARB without code changes. |
| `AppLocalizations.of(context)!` at call sites violates the spirit of the no-`!` rule | Low | Low (documented exception) | §7 documents the exception explicitly; `code-reviewer` agent sees this in the spec/plan and won't flag it. |
| Adding `generate: true` to `pubspec.yaml` triggers slow `flutter pub get` | Low | Low (one-time cost during dev) | Acceptable; the codegen runs implicitly and is fast enough for the five strings this feature ships. |
| `lib/l10n/` directory placement diverges from the constitution's `lib/core/` convention for cross-feature concerns | Low | Low (Flutter convention favors `lib/l10n/` at the lib root for ARB files) | `lib/l10n/` is the Flutter-recommended location for ARB sources (per the official i18n guide); the generated `AppLocalizations` class is the cross-feature concern, and it lives under `.dart_tool/` (not `lib/core/`). This is acceptable: the constitution's `lib/core/` rule applies to *project-authored* cross-feature code, not to translation source assets, which follow framework convention. |
