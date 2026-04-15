# Plan: Multi-Language Support (English, German, Ukrainian)

**Date**: 2026-04-14
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Wire Flutter's official `flutter_localizations` + `intl` + `flutter gen-l10n` i18n toolchain into dosly for English (default fallback), German, and Ukrainian. Four user-facing strings (`Settings` tooltip + three bottom-nav destination labels) move from hard-coded English literals to ARB-sourced lookups resolved through a generated `AppLocalizations` class. The `'Hello World'` body placeholder on HomeScreen stays hard-coded — it's temporary and will be replaced wholesale when the real Today content ships, so translating it is wasted work. Active locale is auto-resolved from the device locale on every launch; no user-facing picker or persistence — those ship with the future Settings feature.

## Technical Context

**Architecture**: Presentation-layer-only change. ARB files + generated `AppLocalizations` class are presentation concerns and must never be imported from `domain/` (currently moot — no `domain/` exists). No data or domain layer touched.
**Error Handling**: N/A for this feature. `AppLocalizations.of(context)!` is the Flutter-sanctioned non-null pattern when delegates are correctly registered on `MaterialApp`; no `Either<Failure, T>` path applies.
**State Management**: No new reactive state. Device-locale resolution is free from `MaterialApp`'s built-in handling. Deliberately no `localeController` — no UI would drive it in this feature.

## Constitution Compliance

- **§2.1 Layer Boundaries** — ✅ compliant. `AppLocalizations` stays in presentation.
- **§2.3 Dependency Rules (add via `flutter pub add`)** — ✅ compliant. Dependencies are added via `flutter pub add`; the `flutter: { generate: true }` flag is a manifest edit that `pub add` cannot set — this is an accepted exception already called out in the spec §7.
- **§3.1 `dart analyze` clean** — ✅ target; enforced by AC-10.
- **§3.5 No magic strings** — ✅ compliant. All translated strings live in ARB files keyed by symbolic identifiers (`settingsTooltip`, `bottomNavToday`, `bottomNavMeds`, `bottomNavHistory`).
- **§4.1.1 Prefer `const` constructors** — ⚠️ requires attention. `NavigationDestination` instances inside `HomeBottomNav` lose `const` because labels become runtime values; the outer `HomeBottomNav` constructor stays `const`. Documented in spec §3.4. Applies the existing `_noop` pattern already in the file.
- **§4.2.1 No `!` null assertion operator** — ⚠️ single sanctioned exception at `AppLocalizations.of(context)!` call sites. Documented in spec §7. `code-reviewer` sees this in spec/plan and will not flag it.
- **Memory entry: `NavigationBar` has NO `const` constructor** — ✅ honored. Existing structure already places `const` on leaves (`Divider`, destinations), outer `NavigationBar` is non-const. This feature keeps that shape; only the three `NavigationDestination` children lose their `const`.

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|---|---|---|
| Build config | i18n codegen config + generate flag | `pubspec.yaml` (modify), `l10n.yaml` (new) |
| Translation source | ARB resource bundles (source of truth) | `lib/l10n/app_en.arb` (new), `lib/l10n/app_de.arb` (new), `lib/l10n/app_uk.arb` (new) |
| Generated code | Typed `AppLocalizations` class + delegates | `lib/l10n/app_localizations.dart` (generated, committed), `lib/l10n/app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` (generated, committed) |
| Presentation (app root) | Wire delegates + supportedLocales | `lib/app.dart` (modify) |
| Presentation (Home) | Replace literals with `AppLocalizations` lookups | `lib/features/home/presentation/screens/home_screen.dart` (modify), `lib/features/home/presentation/widgets/home_bottom_nav.dart` (modify) |
| Tests (existing) | Register delegates on `_harness()` `MaterialApp` | `test/features/home/presentation/widgets/home_bottom_nav_test.dart` (modify) |
| Tests (new) | Multi-locale assertions for `HomeBottomNav` | `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` (new) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|---|---|---|---|
| i18n toolchain | `flutter_localizations` + `intl` + `flutter gen-l10n` | First-party, ARB is industry standard, type-safe codegen, matches spec §7 MUST-follow rule | `easy_localization` (third-party, magic strings, violates §3.5); hand-rolled map (reinvents codegen) |
| Generated-code hosting | `synthetic-package: false`, files committed at `lib/l10n/` | Current Flutter recommendation (synthetic package is deprecated); fresh clones compile before `flutter pub get` runs; consistent with how other Flutter codegen (freezed, drift, riverpod) would land when added | Deprecated `synthetic-package: true` + `package:flutter_gen/...` import (what spec §3.1 assumed) — rejected per [research.md](research.md) |
| `intl` version pin | `intl: any` | Lets pub solver align with whatever `intl` the Flutter SDK already pins transitively; avoids the "my pin vs SDK's pin" conflict the spec §9 Risk #2 calls out | Explicit `^0.x.y` pin (brittle against Flutter SDK upgrades) |
| Import path in widgets | `package:dosly/l10n/app_localizations.dart` | Flows from `synthetic-package: false` choice; standard Dart package-relative import, no virtual-package magic | `package:flutter_gen/gen_l10n/...` (tied to deprecated approach) |
| ARB directory location | `lib/l10n/` (Flutter default) | Matches Flutter's recommended convention; already acknowledged and accepted by spec §9 risks row | `lib/core/l10n/` (fights Flutter default for no benefit) |
| Locale resolution | Flutter default (no custom `localeResolutionCallback`) | Default `BasicLocaleListResolutionCallback` already falls back to English for unsupported locales — exactly what AC-9 (unsupported-locale fallback) and spec §3.2 require | Custom callback (unnecessary code, more surface to test) |
| `localeController` | **None** | No UI in this feature drives reactive state; mirroring `themeController` prematurely adds dead code. Will ship with future Settings feature. | Preemptive `localeController` (YAGNI; spec §2 explicitly calls this out) |
| `HomeBottomNav` structure | Keep outer `const` constructor + `_noop` function; make the three `NavigationDestination` children non-const because their `label:` is now a runtime value | Preserves const-ness where possible per §4.1.1; already-proven pattern from feature 005 (MEMORY.md) | Reshape widget into Stateful or add a builder — over-engineering for 3 labels |
| Committing generated files | **Yes** — commit `lib/l10n/app_localizations*.dart` to Git | With `synthetic-package: false`, generated files are normal source; committing ensures fresh clones and CI compile without running codegen first; matches the project's likely future choice when freezed/riverpod/drift ship (those also commit generated `.g.dart` / `.freezed.dart`) | `.gitignore` them (forces `flutter pub get` before first compile; not idiomatic for non-synthetic gen_l10n output) |

### File Impact

| File | Action | What Changes |
|---|---|---|
| `pubspec.yaml` | Modify | Add `flutter_localizations: { sdk: flutter }` and `intl: any` under `dependencies:` (via `flutter pub add flutter_localizations --sdk=flutter` then `flutter pub add intl:any`). Add `generate: true` under the `flutter:` section (manual edit — `pub add` can't set it). |
| `pubspec.lock` | Modify | Updated by `flutter pub get` — commit the resolved versions. |
| `l10n.yaml` | Create | Repo root. Contents: `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `output-class: AppLocalizations`, `synthetic-package: false`. |
| `lib/l10n/app_en.arb` | Create | Five keys with English values + `@key` metadata block each (one-sentence `description` per key). |
| `lib/l10n/app_de.arb` | Create | Same five keys, German values, `"@@locale": "de"`, no `@key` metadata. |
| `lib/l10n/app_uk.arb` | Create | Same five keys, Ukrainian values, `"@@locale": "uk"`, no `@key` metadata. |
| `lib/l10n/app_localizations.dart` | Create (generated) | Produced by `flutter gen-l10n`. Typed `AppLocalizations` class with static `localizationsDelegates` and `supportedLocales` and abstract getters for each key. Committed. |
| `lib/l10n/app_localizations_en.dart` | Create (generated) | English subclass. Committed. |
| `lib/l10n/app_localizations_de.dart` | Create (generated) | German subclass. Committed. |
| `lib/l10n/app_localizations_uk.dart` | Create (generated) | Ukrainian subclass. Committed. |
| `lib/app.dart` | Modify | Add `import 'l10n/app_localizations.dart';` and set `localizationsDelegates: AppLocalizations.localizationsDelegates` + `supportedLocales: AppLocalizations.supportedLocales` on `MaterialApp.router`. Leave `title: 'dosly'` unchanged. Leave `ListenableBuilder(listenable: themeController, ...)` structure unchanged. |
| `lib/features/home/presentation/screens/home_screen.dart` | Modify | Import `AppLocalizations`. Replace `tooltip: 'Settings'` with `tooltip: AppLocalizations.of(context)!.settingsTooltip` (line 45 area). Leave `'Dosly'` AppBar title (line 40), `'Hello World'` body placeholder (line 57 — temporary; translating a placeholder is wasted work), and `'Theme preview'` button label (line 64) untouched. |
| `lib/features/home/presentation/widgets/home_bottom_nav.dart` | Modify | Import `AppLocalizations`. Inside `build()`, fetch `final l = AppLocalizations.of(context)!;` then use `l.bottomNavToday / bottomNavMeds / bottomNavHistory` in the three `NavigationDestination.label:` arguments. Drop `const` from the three `NavigationDestination` instances (labels are runtime). Keep outer `const HomeBottomNav({super.key})` constructor, top-level `_noop`, and `Divider(height: 1, thickness: 1)` const-ness. `NavigationBar` stays non-const (as it already is per MEMORY.md). |
| `test/features/home/presentation/widgets/home_bottom_nav_test.dart` | Modify | Import `AppLocalizations` and `package:flutter_localizations/flutter_localizations.dart`. Update `_harness()`: outer `MaterialApp` (loses `const` because `localizationsDelegates` is a runtime list) gains `localizationsDelegates: AppLocalizations.localizationsDelegates` and `supportedLocales: AppLocalizations.supportedLocales`. No `locale:` override — English is the implicit default in widget tests. Existing assertions (`find.text('Today'/'Meds'/'History')`) stay unchanged. |
| `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` | Create | Three `testWidgets` cases: (1) pump under `Locale('de')` → assert `Heute / Medikamente / Verlauf`; (2) pump under `Locale('uk')` → assert `Сьогодні / Ліки / Історія`; (3) pump under `Locale('fr')` → assert English fallback labels. Harness reuses the same delegate wiring via a shared `_harness({required Locale locale})` helper in this file (don't export from the existing test file). |
| `.gitignore` | No change | `.dart_tool/` is already ignored. `lib/l10n/` generated files are intentionally committed; no ignore rule needed. |

### Documentation Impact

| Doc File | Action | What Changes |
|---|---|---|
| `docs/features/i18n.md` | Create | New file. Documents: toolchain choice, how to add a new string (edit `app_en.arb` → run `flutter gen-l10n` or `flutter pub get` → call site reads `AppLocalizations.of(context)!.newKey`), how to add a new locale (create `app_xx.arb` with all keys), why we chose `synthetic-package: false`, why no `localeController` yet. |
| `docs/architecture.md` | Update | Add a short section on i18n placement: presentation-only, ARB sources at `lib/l10n/`, generated code committed there, forbidden in `domain/`. |
| `docs/features/home.md` | Update | Note that `HomeBottomNav` destination labels and `HomeScreen` Settings tooltip + body placeholder now flow from `AppLocalizations`. |

Per spec §4 (last row), documentation updates are produced by `tech-writer` during `/finalize`, not as part of this plan's tasks. The table above is what `tech-writer` will touch — listed here for cross-reference only.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `intl: any` resolves to a version Flutter's `flutter_test` transitively pins to a *different* version, causing solver conflict | Low | Medium (build block) | If `flutter pub add intl:any` fails resolution, fall back to `intl: ^<version>` where `<version>` matches the one `flutter pub deps \| grep intl` shows Flutter itself using. Captured from spec §9 Risk #2. |
| `synthetic-package: false` is unfamiliar to future contributors who expect the old synthetic-package import | Low | Low (cosmetic only) | `docs/features/i18n.md` calls out the decision; code imports clearly show `package:dosly/l10n/...` so nothing mysterious happens at call sites. |
| Generated `lib/l10n/app_localizations*.dart` files get into a spec/ARB drift state where ARBs change but generated files aren't regenerated (e.g., a PR that edits ARB but forgets to run codegen) | Low | Medium (stale translations shipped) | `flutter pub get` (run by CI and by `flutter test`) regenerates automatically when `generate: true` is set. The PostToolUse `dart analyze` hook will flag a missing getter if someone added an ARB key but didn't regenerate. `/execute-task`'s verification phase runs `flutter test` which in turn triggers regeneration. |
| `HomeBottomNav` `const` loss has a ripple — some parent widget previously relied on the three `const NavigationDestination`s to lift the surrounding list to `const` | Low | Low | Inspection of `home_bottom_nav.dart` shows the destinations list is already non-const (the `NavigationBar` itself is non-const per MEMORY.md). The const loss is strictly local to the three children. No ripple. |
| German `Medikamente` overflows `NavigationDestination` label slot on narrow phones | Medium | Low (text truncates, no crash) | Accept per spec §8 Q1; user verifies manually via AC-13; follow-up spec if truncation observed. |
| Spec text references the deprecated synthetic-package import path (AC-4, §4 last row) — drift with this plan's decision | Certain | Low (doc drift only — still the same feature) | This plan's Phase 2.5 cross-reference surfaces the drift. User already acknowledged by approving `/plan` to proceed with modernized decisions. No code impact. |
| Widget tests that set `Locale('fr')` could accidentally resolve to something other than English if a default delegate chain shifts | Low | Low | AC-9 test directly asserts English fallback for `fr`; failure is caught at test time. No code relies on the fallback matching anything except the explicitly-listed English values. |

## Dependencies

### Packages added
- `flutter_localizations: { sdk: flutter }` — adds the three Material/Cupertino/Widgets localization delegates. Ships with Flutter SDK; no pub.dev download.
- `intl: any` — resolved version TBD by pub solver; committed via `pubspec.lock`.

### Tooling
- `flutter gen-l10n` — runs implicitly during `flutter pub get` when `generate: true` is set. No manual invocation required, though can be run explicitly for debugging.

### Environment variables
- None.

### Configuration
- `l10n.yaml` at repo root (new).
- `pubspec.yaml` — adds `generate: true` under `flutter:` section.

## Plan-Spec Cross-Reference

Every AC in spec §5 maps to a clear implementation path below:

| AC | Mapped to Plan |
|---|---|
| AC-1 (pubspec has deps + `generate: true`) | "File Impact" → `pubspec.yaml` |
| AC-2 (l10n.yaml exists with correct keys) | "File Impact" → `l10n.yaml`. **Drift note**: the plan adds `synthetic-package: false` to the list; see AC-4 note below. |
| AC-3 (three ARB files, five keys each, `@key` metadata in en) | "File Impact" → three ARB file rows |
| AC-4 (gen produces `AppLocalizations` importable via a path) | "File Impact" → four generated file rows. Spec AC-4 has been updated to reference `package:dosly/l10n/app_localizations.dart` (aligned with plan). |
| AC-5 (MaterialApp.router wired with delegates) | "File Impact" → `lib/app.dart` |
| AC-6 (HomeScreen literals replaced, Dosly/Theme preview untouched) | "File Impact" → `home_screen.dart` |
| AC-7 (HomeBottomNav literals replaced, outer const preserved) | "File Impact" → `home_bottom_nav.dart` |
| AC-8 (existing tests still pass) | "File Impact" → harness update row; delegate registration is the only required change |
| AC-9 (new locale tests for de/uk/fr fallback) | "File Impact" → new `home_bottom_nav_l10n_test.dart` row |
| AC-10 (`dart analyze` clean) | Enforced by project's PostToolUse hook + final verification |
| AC-11 (`flutter test` clean) | Enforced by `/execute-task` verification phase |
| AC-12 (`flutter build apk --debug` succeeds) | Enforced by `/execute-task` verification phase |
| AC-13 (manual on-device verification) | Deferred to user post-merge per spec text; no code deliverable |

### Reverse check: plan additions beyond spec "Affected Areas"

| Addition | Status |
|---|---|
| `pubspec.lock` (committed lock-file update) | Implicit in AC-1 (`flutter pub add` updates the lock); noted here for completeness — not a spec drift. |
| `lib/l10n/app_localizations*.dart` committed to Git (vs spec §4 stating generated files are NOT committed because they live in `.dart_tool/`) | **Spec drift** — direct consequence of `synthetic-package: false` decision. Flagged to user and documented in [research.md](research.md) "Spec Deviations". Plan is the authoritative source going forward; `/breakdown` should honor the plan's choice. |

## Supporting Documents

- [Research](research.md) — Context7-verified finding that spec's synthetic-package assumption is deprecated; captures alternative comparison tables and decision rationale.
- Data Model — not applicable (no entities introduced by this feature).
- Contracts — not applicable (no API surface introduced by this feature).
