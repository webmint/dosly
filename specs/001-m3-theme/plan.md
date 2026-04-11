# Plan: Material Design 3 Theme

**Date**: 2026-04-11
**Spec**: [spec.md](spec.md)
**Status**: Approved
**Branch**: `spec/001-m3-theme`

## Summary

Hand-code Flutter `ColorScheme` literals for both light and dark using exact hex tokens from `dosly_m3_template.html` (Theme Builder seed `#4CAF50`). Bundle four Roboto TTF weights as font assets. Build `AppTheme.lightTheme` / `AppTheme.darkTheme` `ThemeData` instances. Drive `MaterialApp.themeMode` with a plain `ValueNotifier<ThemeMode>`-based `ThemeController` (no Riverpod yet). Replace `lib/main.dart` counter boilerplate with a tiny `DoslyApp` root and a `ThemePreviewScreen` that exercises every color role, text style, and common widget so the design can be visually verified end-to-end.

## Technical Context

**Architecture**: This spec touches **only** `lib/core/theme/` (theme infrastructure) and one feature folder `lib/features/theme_preview/presentation/` (the preview screen). It does NOT create `domain/` or `data/` layers — there is no domain logic, no data persistence, no business rules. The theme module sits entirely under `lib/core/` per constitution Section 2.2 ("All theme-related code MUST live under `lib/core/theme/`").

**Error Handling**: N/A — no fallible operations. The theme module has no I/O, no network, no parsing. Failures cannot occur. `Either<Failure, T>` is irrelevant for this spec.

**State Management**: One piece of state — `ThemeMode`. Held in a top-level `ValueNotifier<ThemeMode>` subclass (`ThemeController`). NOT a Riverpod provider — Riverpod is intentionally out of scope (spec Section 6) so the foundational scaffolding stays separable. The `ListenableBuilder` widget at the root of `DoslyApp` rebuilds the `MaterialApp` when the controller's value changes. In-memory only — restart resets to `ThemeMode.system`. This is acknowledged in spec Section 6 (persistence belongs to a future Settings feature).

## Constitution Compliance

| Rule | Status |
|---|---|
| **§2.1 Layer boundaries** — `lib/core/` is feature-agnostic | ✅ Compliant. Theme module has no domain knowledge. |
| **§2.1 No `package:flutter/*` in `domain/`** | ✅ Trivially compliant — no `domain/` files created. |
| **§2.2 Theme code under `lib/core/theme/`** | ✅ All four theme files live under `lib/core/theme/`. |
| **§2.3 `flutter pub add` for new deps** | ✅ Compliant — no new package dependencies. Only an asset addition. |
| **§3.1 Type safety — no `dynamic`, no `!`, no unchecked `as`** | ✅ Compliant. Theme code is pure constants and a typed `ValueNotifier`. |
| **§3.1 `freezed` for entities** | ✅ N/A — no entities. |
| **§3.1 Domain IDs as value objects** | ✅ N/A — no IDs. |
| **§3.4 Mandatory unit tests for domain & data** | ✅ Compliant — no domain or data layer in this spec. Optional theme tests included anyway (AC-1, AC-2, AC-3 enforced via `app_color_schemes_test.dart`). |
| **§4.1.1 Always use `const` constructors** | ✅ Compliant. `ColorScheme` and `ThemeData` constructors are `const` where the API allows. |
| **§4.1.1 Always declare return types** | ✅ Compliant. All public getters have explicit return types. |
| **§4.2.1 No `print()` / `debugPrint()`** | ✅ Compliant. Zero diagnostic output. |
| **§4.2.1 No hardcoded `Color(0xFF...)` outside `lib/core/theme/`** | ✅ Compliant. Every color literal lives in `app_color_schemes.dart`. The preview screen reads from `Theme.of(context).colorScheme`. |
| **§4.2.1 No `BuildContext` after `await` without `mounted`** | ✅ Trivially compliant — no async work in any of the new code. |
| **§4.2.1 No `SharedPreferences` for medication data** | ✅ Trivially compliant — theme persistence is explicitly out of scope. |
| **§4.3.1 Named parameters for constructors with > 1 param** | ✅ Compliant. `ColorSwatchCard(role:, color:, onColor:, label:)`, `TypographySample(styleName:, style:)`. |
| **§6.4 Dartdoc on public APIs** | ✅ Compliant. `///` comments on `ThemeController`, `AppTheme`, `lightColorScheme`, `darkColorScheme`, `DoslyApp`, `ThemePreviewScreen`, and the public widgets. |
| **§7.1 First-files order** | ⚠ Partial deviation: this spec creates `lib/core/theme/` (item 8 in the order) WITHOUT first creating items 1–7 (`failures.dart`, `app_clock.dart`, `logger.dart`, `database.dart`, etc.). This is intentional — the spec is scoped to "theme only" per the user's choice. The other foundations land in their own specs. **Risk**: when `failures.dart` etc. are added later, no theme rework should be needed (theme has zero dependencies on them). Acceptable. |

No NON-NEGOTIABLE violations.

## Implementation Approach

### Layer Map

| Layer | What | Files |
|---|---|---|
| **Core** | Color tokens (light + dark `ColorScheme` literals) | `lib/core/theme/app_color_schemes.dart` *(new)* |
| **Core** | Text theme factory (Roboto-based M3 type scale) | `lib/core/theme/app_text_theme.dart` *(new)* |
| **Core** | Full `ThemeData` for both schemes (component themes wired) | `lib/core/theme/app_theme.dart` *(new)* |
| **Core** | `ThemeController` (`ValueNotifier<ThemeMode>` subclass) + module-level singleton | `lib/core/theme/theme_controller.dart` *(new)* |
| **App root** | `DoslyApp` widget — wraps `MaterialApp` in `ListenableBuilder` driven by `themeController` | `lib/app.dart` *(new)* |
| **Entry point** | `main()` — 3-line replacement, just `runApp(const DoslyApp())` | `lib/main.dart` *(replace)* |
| **Feature: theme_preview** | Preview screen exercising every role, text style, and common widget | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` *(new)* |
| **Feature: theme_preview** | `ColorSwatchCard` widget — paints one role's bg + on-color text + hex label | `lib/features/theme_preview/presentation/widgets/color_swatch_card.dart` *(new)* |
| **Feature: theme_preview** | `TypographySample` widget — one row per text style | `lib/features/theme_preview/presentation/widgets/typography_sample.dart` *(new)* |
| **Assets** | Four Roboto TTF files (300/400/500/700) | `assets/fonts/Roboto-Light.ttf`, `Roboto-Regular.ttf`, `Roboto-Medium.ttf`, `Roboto-Bold.ttf` *(new)* |
| **Assets** | License attribution for Roboto (Apache 2.0) | `assets/fonts/LICENSE.txt` *(new)* |
| **Assets** | Source notes (download URL, date, version) | `assets/fonts/SOURCE.md` *(new)* |
| **Pubspec** | Declare four font weights under `flutter.fonts`; update `description` | `pubspec.yaml` *(modify)* |
| **Smoke test** | Replace counter test with theme preview pump test | `test/widget_test.dart` *(replace)* |
| **Theme tests** | Per-field hex assertions for both schemes | `test/core/theme/app_color_schemes_test.dart` *(new)* |
| **Theme tests** | `ThemeController` behavior tests | `test/core/theme/theme_controller_test.dart` *(new)* |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|---|---|---|---|
| **How to construct ColorScheme** | Hand-coded `const ColorScheme(brightness:..., primary: Color(0xFF2E7D32), ...)` literals — one for light, one for dark | Spec AC-1 forbids `fromSeed`. Single source of truth. Deterministic. Each hex visible in source. | `fromSeed(...).copyWith(...)` (rejected — spec violation, two sources of truth); algorithmic derivation (overkill). See `research.md`. |
| **Where colors live** | `lib/core/theme/app_color_schemes.dart` — exports `const lightColorScheme` and `const darkColorScheme` as top-level finals | Constitution §2.2 + §4.2.1. Single file = single source of truth. | Inlining in `app_theme.dart` (works but mixes concerns); per-role files (over-engineered). |
| **`surfaceBright` / `surfaceDim` derivation** | Reuse adjacent container tones — light: `Bright = ContainerLow`, `Dim = ContainerHighest`; dark: `Bright = ContainerHigh`, `Dim = ContainerLowest` | HTML doesn't specify them. M3 semantics preserved. Documented inline. | HSL math (overkill, error-prone); equal to `surface` (loses semantic distinction). |
| **Fixed variants (`primaryFixed`, etc.)** | Omit (let Flutter use null defaults) | HTML doesn't specify them. No widget in this spec needs them. Adding them blind would invent values not in the design. | Derive from primary container (would diverge from design intent). |
| **State management for `ThemeMode`** | Plain `ValueNotifier<ThemeMode>` subclass with a top-level `final themeController` instance | Spec Section 6 forbids Riverpod in this spec. `ValueNotifier` ships with Flutter. `ListenableBuilder` rebuilds `MaterialApp` cleanly. Single dependency-free root state. | Riverpod provider (out of scope per spec); `InheritedWidget` (more boilerplate, no benefit); `setState` in a `StatefulWidget` root (works but harder to test in isolation). |
| **Persistence** | None — in-memory only, resets to `ThemeMode.system` on restart | Spec Section 6 explicitly excludes persistence. Persistence belongs to a future Settings feature that uses drift. | `SharedPreferences` (forbidden by constitution §4.2.1 for medication data, allowed for theme — but adds dep + state-restoration complexity). |
| **Where the preview screen lives** | `lib/features/theme_preview/presentation/screens/...` (treat as a one-off feature folder) | Keeps `lib/core/` clean (per constitution §2.1). Follows the per-feature folder pattern. Easy to delete later when real screens land. | `lib/core/theme/preview/` (mixes UI into `core/`, violates §2.1). |
| **Roboto source** | Manual download from `fonts.google.com/specimen/Roboto` during implementation; record URL + date + version in `assets/fonts/SOURCE.md` | Reproducible. License-clean (Apache 2.0). Implementer can re-download if needed. | `google_fonts` package (constitution §3 — no runtime network calls); checked-in fork (origin unclear). |
| **Roboto weights to ship** | 300, 400, 500, 700 only — skip weight 600 | M3 type scale uses 400/500 only. The HTML uses weight 600 in 1-2 places (line 511) but those are M3 spec deviations. Skipping 600 keeps the bundle small (~600 KB total). | Ship 600 too (extra ~150 KB for marginal value); ship variable font (single file ~700 KB but compatibility-fragile across Flutter versions). |
| **Material Icons style** | All `Icons.xxx_rounded` variants (matches HTML's `material-icons-round`) | Already shipped with Flutter — zero size cost. Matches design exactly. | Default Filled style (would mismatch design); Symbols variable font (requires asset, complexity). |
| **`useMaterial3` flag** | Set explicitly to `true` in both `ThemeData` constructors | Defensive — Flutter's default is currently `true` but explicit is clearer and survives future flag flips. | Rely on default (works but less explicit). |
| **`debugShowCheckedModeBanner`** | Set to `false` in `MaterialApp` | Cleaner preview — no debug ribbon obscuring the theme | Leave default `true` (debug ribbon overlaps top-right of app bar). |
| **Test coverage** | 3 test files: smoke pump test + per-hex color assertions + ThemeController behavior | Spec AC-2/AC-3 require exact hex verification. AC-12 requires `flutter test` to pass. AC-6 requires testable controller behavior. | Skip tests (violates AC-12); single mega-test file (harder to scan failures). |

### File Impact

| File | Action | What Changes |
|---|---|---|
| `lib/core/theme/app_color_schemes.dart` | Create | Top-level `const ColorScheme lightColorScheme` and `const ColorScheme darkColorScheme` literals. ~80 lines total. |
| `lib/core/theme/app_text_theme.dart` | Create | `class AppTextTheme` with static `const TextTheme textTheme` factory using `fontFamily: 'Roboto'` and the M3 type scale. ~50 lines. |
| `lib/core/theme/app_theme.dart` | Create | `class AppTheme { static ThemeData get lightTheme; static ThemeData get darkTheme; }`. Each getter builds `ThemeData(useMaterial3: true, colorScheme: ..., textTheme: ..., iconTheme: ..., appBarTheme: ..., cardTheme: ..., filledButtonTheme: ..., outlinedButtonTheme: ..., textButtonTheme: ..., chipTheme: ..., floatingActionButtonTheme: ..., inputDecorationTheme: ..., dividerTheme: ..., bottomNavigationBarTheme: ...)`. ~120 lines. |
| `lib/core/theme/theme_controller.dart` | Create | `class ThemeController extends ValueNotifier<ThemeMode>` with constructor defaulting to `ThemeMode.system`, plus `void setMode(ThemeMode mode)` and `void cycle()` (system → light → dark → system). Module-level `final themeController = ThemeController();`. ~30 lines. |
| `lib/app.dart` | Create | `class DoslyApp extends StatelessWidget` whose `build` returns `ListenableBuilder(listenable: themeController, builder: (_, __) => MaterialApp(...))`. ~30 lines. |
| `lib/main.dart` | Replace | Strip from 122 lines to 4: `import 'package:flutter/material.dart';` + `import 'app.dart';` + `void main() => runApp(const DoslyApp());`. |
| `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | Create | `class ThemePreviewScreen extends StatelessWidget`. App bar with cycle action. Body is a `SingleChildScrollView` with three sections: Color palette (grid of `ColorSwatchCard`), Typography (column of `TypographySample`), Components (row/wrap of `FilledButton`, `FilledButton.tonal`, `OutlinedButton`, `TextButton`, `Card`, `Chip`, `FloatingActionButton`, `Switch`, `TextField`). ~200 lines. |
| `lib/features/theme_preview/presentation/widgets/color_swatch_card.dart` | Create | `class ColorSwatchCard extends StatelessWidget` — `Container` painted with `color`, with `Text(role)` and `Text(hex)` in `onColor`. ~40 lines. |
| `lib/features/theme_preview/presentation/widgets/typography_sample.dart` | Create | `class TypographySample extends StatelessWidget` — row showing the style name + a sample line. ~30 lines. |
| `assets/fonts/Roboto-Light.ttf` | Add | Roboto Light (weight 300), downloaded from fonts.google.com |
| `assets/fonts/Roboto-Regular.ttf` | Add | Roboto Regular (weight 400) |
| `assets/fonts/Roboto-Medium.ttf` | Add | Roboto Medium (weight 500) |
| `assets/fonts/Roboto-Bold.ttf` | Add | Roboto Bold (weight 700) |
| `assets/fonts/LICENSE.txt` | Add | Roboto Apache 2.0 license text |
| `assets/fonts/SOURCE.md` | Add | Download URL, date, file SHA-256 hashes for verification |
| `pubspec.yaml` | Modify | Update `description` to "Personal medication tracking app". Add `flutter.fonts` block declaring the four Roboto weights. |
| `test/widget_test.dart` | Replace | Old: pumps `MyApp`, taps counter. New: pumps `DoslyApp`, verifies `ThemePreviewScreen` is found, verifies cycling theme mode does not throw. |
| `test/core/theme/app_color_schemes_test.dart` | Create | Per-field hex assertions for every role in both schemes. ~60 tests (one `expect` per role per scheme). |
| `test/core/theme/theme_controller_test.dart` | Create | Tests: default value is `system`; `setMode` updates value; `setMode` notifies listeners; `cycle` advances `system → light → dark → system`. ~40 lines. |

**Files added during planning (not in spec's Affected Areas table)**: `assets/fonts/LICENSE.txt`, `assets/fonts/SOURCE.md`. Both are housekeeping for the bundled font assets — license compliance + reproducibility. Trivial additions.

### Documentation Impact

| Doc File | Action | What Changes |
|---|---|---|
| `docs/architecture.md` | Update | The current stub says "TODO: populate after `/constitute`". Replace with a section describing the theme module: where it lives, the `ThemeController` pattern, the rule about hardcoded colors. ~30 lines added. |
| `docs/features/theme.md` | Create | Feature doc for the theme module. Sections: Overview, How to use the theme in a widget, How to add a new color role, How the theme controller works, How to extend with persistence later. ~80 lines. |
| `docs/overview.md` | Update | Replace the "TODO: populate after `/constitute` and the first feature ships" line with a real one-paragraph description now that we have a constitution and a first feature. |

(`tech-writer` agent runs after the feature is verified, per `/finalize`. The plan just enumerates what will need updating.)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Roboto TTF download requires manual step (no network in agent sandbox) | High | Low | Implementer attempts download; if unavailable, prompts user to drop the four files into `assets/fonts/`. Document SHA-256 hashes for verification. |
| `ColorScheme(...)` constructor signature changes between Flutter versions, breaking the build | Low | Med | Pinned Flutter SDK via `environment.sdk: ^3.11.1` in `pubspec.yaml`. Tests assert only the explicit fields we set. |
| HTML deprecated tokens (`background`, `onBackground`, `surfaceVariant`) cause confusion during implementation | Med | Low | `research.md` explicitly documents the migration. Inline `///` comments in `app_color_schemes.dart` flag dropped tokens. |
| `surfaceBright` / `surfaceDim` derivation diverges from designer intent | Low | Low | Documented in `app_color_schemes.dart` with rationale. Visually verified via the preview screen during AC-13 manual run. |
| 30+ named-parameter `ColorScheme(...)` literal becomes hard to read | Med | Low | Group related fields with blank lines + section comments (`// Primary`, `// Secondary`, ..., `// Surface containers`). |
| Theme preview screen renders differently on iOS vs Android due to platform widget defaults | Low | Low | All widgets used are pure Material — no Cupertino. AC-13 covers both platforms manually. |
| Hot reload after `main.dart` rewrite loses widget state | Low | Low | One-time hot restart after the first change; subsequent edits are hot-reload-safe. |
| Tests pass on the dev machine but fail in CI due to font fallback | Low | Low | `flutter_test` doesn't require real fonts to load — it uses `Ahem` test font. Tests don't assert glyph metrics. |
| Theme controller singleton makes parallel widget tests flaky (shared state across tests) | Med | Med | `theme_controller_test.dart` instantiates `ThemeController()` directly (not the singleton). Widget test resets the singleton in `setUp` if it's used. |
| `dart analyze` strict-mode warnings on `lints` not yet enabled | Low | Low | `analysis_options.yaml` strict mode is OUT OF SCOPE per spec — current `flutter_lints` will accept the code. Verify with `dart analyze` before marking AC-11 complete. |
| `flutter pub get` not run after pubspec edits → fonts not bundled | Low | Med | Implementation phase explicitly runs `flutter pub get` after pubspec changes. PostToolUse hook (`dart analyze`) won't catch missing fonts but the manual `flutter run` (AC-13) will. |
| `ColorScheme` constructor in this Flutter version requires `surfaceBright`/`surfaceDim` as non-nullable | Med | Low | Plan supplies them anyway (derived). If they're nullable, plan still works. |

## Dependencies

**No new package dependencies.** Everything used is built into Flutter:
- `package:flutter/material.dart` — `ColorScheme`, `ThemeData`, `MaterialApp`, `ValueNotifier`, `ListenableBuilder`, `Icons.xxx_rounded`
- `package:flutter/foundation.dart` — `ValueNotifier` base class

**Asset additions only**:
- 4 × Roboto TTF files (~150 KB each, ~600 KB total)
- 1 × LICENSE.txt
- 1 × SOURCE.md

**Implicit external dependency**: `fonts.google.com/specimen/Roboto` for the one-time font download during implementation. After download, the project is fully self-contained (constitution §3 — no runtime network).

## Plan-Spec Cross-Reference Check

Verifying every AC has a clear implementation path:

| AC | Coverage in plan |
|---|---|
| AC-1 (`ColorScheme` literals, no fromSeed) | ✅ `app_color_schemes.dart` row in File Impact + Key Design Decision row 1 |
| AC-2 (light scheme spot-checks) | ✅ `app_color_schemes_test.dart` asserts every role hex |
| AC-3 (dark scheme spot-checks) | ✅ same test file covers both schemes |
| AC-4 (`AppTheme.lightTheme` / `darkTheme`) | ✅ `app_theme.dart` row in File Impact |
| AC-5 (pubspec font declarations + .ttf files exist) | ✅ pubspec.yaml row + 4 asset rows in File Impact |
| AC-6 (`ThemeController` API + default + setMode) | ✅ `theme_controller.dart` row + `theme_controller_test.dart` row |
| AC-7 (`DoslyApp` with `ListenableBuilder` + MaterialApp config) | ✅ `lib/app.dart` row in File Impact |
| AC-8 (`lib/main.dart` reduced to 3 lines) | ✅ `lib/main.dart` "Replace" row in File Impact |
| AC-9 (`ThemePreviewScreen` content) | ✅ Screen + 2 widgets + Component samples in Layer Map |
| AC-10 (rounded icons only) | ✅ Key Design Decision row 10 |
| AC-11 (`dart analyze` clean) | ✅ Constitution Compliance + Risk row 10 |
| AC-12 (`flutter test` passes) | ✅ 3 test files in File Impact |
| AC-13 (manual `flutter run` on iOS + Android) | ✅ Manual verification step — listed in Risk Assessment row 6 + Open Questions Q1 timing |
| AC-14 (no hardcoded `Color(0xFF...)` outside `lib/core/theme/`) | ✅ Constitution Compliance §4.2.1 row + grep check during /verify |
| AC-15 (no `package:flutter/*` in `domain/`) | ✅ Trivially true — no `domain/` files. Constitution §2.1 row. |

Every AC has an implementation path. No gaps.

## Open Questions Carried From Spec

These were noted as "minor" in spec Section 8 and remain to be answered during implementation, not blocking the plan:

- **Q1** (Roboto download source) → resolved in plan: download from fonts.google.com during implementation; record in `SOURCE.md`
- **Q2** (skip weight 600) → resolved: skip
- **Q3** (preview screen location) → resolved: `lib/features/theme_preview/`
- **Q4** (update pubspec description) → resolved: include in this spec

## Supporting Documents

- [Spec](spec.md)
- [Research](research.md) — Flutter ColorScheme field naming, deprecated fields, pubspec font syntax

(No `data-model.md` — no entities. No `contracts.md` — no API.)
