# Spec: Material Design 3 Theme

**Date**: 2026-04-11
**Status**: Complete
**Author**: Claude + Mykola
**Branch**: `spec/001-m3-theme`

## 1. Overview

Add Material Design 3 theming to dosly using exact color tokens generated from seed `#4CAF50` (Material Theme Builder). This is the first spec — it establishes the visual foundation (`ColorScheme`, `ThemeData`, typography, font asset) before any feature work begins. Light and dark schemes are both populated, follow-system is the default, and an in-app override toggle is wired but not persisted yet (persistence comes with the future Settings feature).

The work is purely scaffolding — it touches no domain code, adds no Riverpod dependency, creates no use cases or repositories. A small theme preview screen replaces the `flutter create .` counter boilerplate so the design can be visually verified before any feature ships.

## 2. Current State

This is a **greenfield** project. The constitution (Section 7.1) lists `lib/core/theme/app_theme.dart` as one of the first files to create.

Currently:
- `lib/main.dart:1-122` — `flutter create .` boilerplate counter app, using `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` (the default purple Material seed). It's a `StatelessWidget` named `MyApp` with an inline `MyHomePage` counter.
- `test/widget_test.dart:1-30` — boilerplate widget test that pumps `MyApp` and taps the counter button.
- `pubspec.yaml:30-47` — only `cupertino_icons: ^1.0.8` (runtime) and `flutter_lints: ^6.0.0` (dev). No fonts declared.
- `analysis_options.yaml` — default `flutter_lints` only. The strict-mode replacement from constitution Section 7.4 has not been applied yet (out of scope for this spec).
- `lib/core/`, `lib/features/`, `lib/app.dart` — do not exist yet.
- `assets/` directory — does not exist yet.

The design reference at `dosly_m3_template.html` contains the full M3 token output from Material Theme Builder seeded with `#4CAF50`. Both light and dark schemes are defined as CSS custom properties (lines 16–55 light, lines 77–108 dark). The HTML uses Roboto and `material-icons-round` throughout.

Per the constitution:
- Section 2.2 — `lib/core/theme/app_theme.dart` is the canonical location for `ThemeData` + `ColorScheme`
- Section 7.1 — theme is item 8 in the scaffolding-order list (after error/clock/logging/database/notifications/permissions but before routing)
- Section 4.2.1 — hardcoded `Color(0xFF...)` outside `lib/core/theme/` is forbidden in any subsequent feature work

## 3. Desired Behavior

After this spec is implemented:

1. **Color tokens are sourced from the design**: every M3 color role (primary, on-primary, primary-container, ..., surface-container-highest, inverse-surface, scrim) is set to the exact hex value from `dosly_m3_template.html` for both light and dark schemes. NO `ColorScheme.fromSeed` — the Theme Builder output is the source of truth, hand-coded as a `ColorScheme(...)` constructor call.

2. **Roboto is bundled as an asset**: the four weights used in the design (300, 400, 500, 700) ship with the app under `assets/fonts/`. Declared in `pubspec.yaml`. No network call. iOS and Android render identical text.

3. **`ThemeData` is fully wired**: `useMaterial3: true`, `colorScheme`, `textTheme` derived from Roboto, `iconTheme` defaulting to rounded variant, `appBarTheme`, `cardTheme`, `filledButtonTheme`, `outlinedButtonTheme`, `chipTheme`, `floatingActionButtonTheme`, `inputDecorationTheme`, `dividerTheme`, `bottomNavigationBarTheme` configured to match the HTML reference.

4. **Light + dark + system follow**: `MaterialApp` is given both `theme:` and `darkTheme:`, with `themeMode:` driven by a `ValueNotifier<ThemeMode>` exposed by a `ThemeController` in `lib/core/theme/theme_controller.dart`. Default is `ThemeMode.system`. The notifier is in-memory only — restart resets to system.

5. **Theme preview screen replaces the counter**: `lib/main.dart` is rewritten to point at a new `ThemePreviewScreen` (in `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`). The screen shows:
   - App bar with title "dosly · M3 preview"
   - A switcher in the app bar (light / dark / system) that updates the controller
   - Color palette section: a swatch grid showing every color role (filled card with the role color background and the role name + hex in the on-color)
   - Typography section: one sample line per text style (`displayLarge`, `headlineLarge`, `titleLarge`, `bodyLarge`, `bodyMedium`, `labelLarge`, etc.)
   - Component samples: `FilledButton`, `FilledButton.tonal`, `OutlinedButton`, `TextButton`, `Card`, `Chip`, `FloatingActionButton`, `Icon` (rounded variant), `Switch`, `TextField`
6. **Test is updated**: `test/widget_test.dart` no longer references the counter. Instead, it pumps `DoslyApp` and verifies the preview screen renders without errors and that switching themeMode does not throw.

7. **`dart analyze` is clean**: zero warnings, zero errors, after the changes.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Theme module | `lib/core/theme/app_theme.dart` | **Create** — `AppTheme` class with `lightTheme` and `darkTheme` static getters. Hand-coded `ColorScheme` + full `ThemeData` configuration for both. |
| Color tokens | `lib/core/theme/app_color_schemes.dart` | **Create** — exposes `lightColorScheme` and `darkColorScheme` as `const ColorScheme(...)` literals. The single source of truth for every M3 token. |
| Text theme | `lib/core/theme/app_text_theme.dart` | **Create** — `TextTheme` factory built on Roboto with the M3 type scale. |
| Theme controller | `lib/core/theme/theme_controller.dart` | **Create** — `ThemeController` extends `ValueNotifier<ThemeMode>`. Default `ThemeMode.system`. Singleton instance exposed as a top-level `final`. (No Riverpod — kept dependency-free per spec scope.) |
| App root | `lib/app.dart` | **Create** — `DoslyApp` `StatelessWidget` that wraps `MaterialApp` in a `ListenableBuilder(listenable: themeController, ...)` to drive `themeMode`. Sets `theme:`, `darkTheme:`, `home:`, `title: 'dosly'`, `debugShowCheckedModeBanner: false`. |
| Entry point | `lib/main.dart` | **Replace** — strip counter boilerplate. New body: `void main() => runApp(const DoslyApp());`. Imports `app.dart`. |
| Preview screen | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | **Create** — `StatelessWidget` showing color palette grid, typography samples, component samples. Reads from `Theme.of(context)`. App-bar action to cycle ThemeMode via the controller. |
| Preview widgets | `lib/features/theme_preview/presentation/widgets/color_swatch_card.dart` | **Create** — small reusable card that paints a single role's background + on-color text + hex label. |
| Preview widgets | `lib/features/theme_preview/presentation/widgets/typography_sample.dart` | **Create** — small reusable widget that shows a single text-style sample row (style name + sample text). |
| Font assets | `assets/fonts/Roboto-Light.ttf` | **Add** — weight 300 |
| Font assets | `assets/fonts/Roboto-Regular.ttf` | **Add** — weight 400 |
| Font assets | `assets/fonts/Roboto-Medium.ttf` | **Add** — weight 500 |
| Font assets | `assets/fonts/Roboto-Bold.ttf` | **Add** — weight 700 |
| Pubspec | `pubspec.yaml` | **Update** — declare the four Roboto font files under `flutter.fonts`. Update `description` field to "Personal medication tracking app" (replacing "A new Flutter project."). No new dependencies. |
| Smoke test | `test/widget_test.dart` | **Replace** — pumps `DoslyApp`, verifies the preview screen renders, verifies `ThemeController` toggle does not throw. References `package:dosly/app.dart` instead of `package:dosly/main.dart`. |
| Theme tests | `test/core/theme/app_color_schemes_test.dart` | **Create** — verifies key color hex values from the spec match the constants in `app_color_schemes.dart` (so future edits can't silently drift from the design source). |
| Theme tests | `test/core/theme/theme_controller_test.dart` | **Create** — verifies default is `ThemeMode.system`, verifies setter notifies listeners, verifies cycle order if a `cycle()` method is exposed. |

## 5. Acceptance Criteria

- [x] **AC-1**: `lib/core/theme/app_color_schemes.dart` exports `const ColorScheme lightColorScheme` and `const ColorScheme darkColorScheme`. Every required M3 role is set to the exact hex from `dosly_m3_template.html`. No `ColorScheme.fromSeed` is used.
- [x] **AC-2**: For the **light scheme**, `lightColorScheme.primary == Color(0xFF2E7D32)`, `primaryContainer == Color(0xFFB7F0B1)`, `secondary == Color(0xFF52634F)`, `tertiary == Color(0xFF38656A)`, `error == Color(0xFFBA1A1A)`, `surface == Color(0xFFF6FBF3)`, `onSurface == Color(0xFF191C18)`, `outline == Color(0xFF70796E)`, `inversePrimary == Color(0xFF8BD988)`. (The dedicated test asserts every role; AC-2 lists the must-pass spot checks.)
- [x] **AC-3**: For the **dark scheme**, `darkColorScheme.primary == Color(0xFF8BD988)`, `primaryContainer == Color(0xFF0A5210)`, `secondary == Color(0xFFB9CCAF)`, `tertiary == Color(0xFFA0CFD5)`, `error == Color(0xFFFFB4AB)`, `surface == Color(0xFF101410)`, `onSurface == Color(0xFFDFE4DC)`, `outline == Color(0xFF8A9388)`, `inversePrimary == Color(0xFF1B6B1D)`.
- [x] **AC-4**: `lib/core/theme/app_theme.dart` exposes `AppTheme.lightTheme` and `AppTheme.darkTheme`, both `ThemeData` instances with `useMaterial3: true`, the corresponding ColorScheme, and the Roboto-based TextTheme. *(code-reading verified; automated test coverage is a flagged gap)*
- [x] **AC-5**: `pubspec.yaml` declares the four Roboto font files (`Roboto-Light.ttf`, `Roboto-Regular.ttf`, `Roboto-Medium.ttf`, `Roboto-Bold.ttf`) under `flutter.fonts` with the family name `Roboto` and weights 300/400/500/700. The four `.ttf` files exist in `assets/fonts/`.
- [x] **AC-6**: `lib/core/theme/theme_controller.dart` exposes a `ThemeController extends ValueNotifier<ThemeMode>` and a top-level `final themeController = ThemeController()` instance. Default value is `ThemeMode.system`. A method `void setMode(ThemeMode mode)` updates the value (and notifies listeners).
- [x] **AC-7**: `lib/app.dart` defines `DoslyApp` (a `StatelessWidget`). Its `build` method returns a `ListenableBuilder` wrapping `MaterialApp`, with `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, `themeMode: themeController.value`, `title: 'dosly'`, `debugShowCheckedModeBanner: false`, and `home: const ThemePreviewScreen()`. *(code-reading verified; exact field assertions are a flagged partial gap)*
- [x] **AC-8**: `lib/main.dart` is reduced to ~3 lines: `import 'package:flutter/material.dart';` + `import 'app.dart';` + `void main() => runApp(const DoslyApp());`. NO counter, NO `MyApp`, NO `MyHomePage`. *(implemented as 7-line block-body equivalent; counter boilerplate fully removed)*
- [x] **AC-9**: `ThemePreviewScreen` exists at the path in Section 4 and renders without throwing on both light and dark schemes. The screen displays:
  - An `AppBar` with title `"dosly · M3 preview"` and a trailing `IconButton` whose tooltip reads "Cycle theme mode" and which calls `themeController.setMode(...)` to advance through `system → light → dark → system`
  - At least one `ColorSwatchCard` per color role (primary, on-primary, primary-container, on-primary-container, secondary, on-secondary, secondary-container, on-secondary-container, tertiary, on-tertiary, tertiary-container, on-tertiary-container, error, on-error, error-container, on-error-container, surface, on-surface, surface-variant, on-surface-variant, outline, outline-variant, inverse-surface, inverse-on-surface, inverse-primary)
  - Typography samples for `displayLarge`, `headlineLarge`, `titleLarge`, `bodyLarge`, `bodyMedium`, `labelLarge`, `labelMedium`
  - One instance each of: `FilledButton`, `FilledButton.tonal`, `OutlinedButton`, `TextButton`, `Card`, `Chip`, `FloatingActionButton` (with a rounded icon), `Switch`, `TextField` with label and helper text *(code-reading verified; structural test presence is a flagged partial gap)*
- [x] **AC-10**: All `Icon` widgets in the preview screen use rounded variants (`Icons.xxx_rounded`).
- [x] **AC-11**: `dart analyze` reports zero issues across `lib/` and `test/` after the implementation.
- [x] **AC-12**: `flutter test` passes. The replaced `test/widget_test.dart` and the two new tests under `test/core/theme/` all pass. *(79/79)*
- [ ] **AC-13**: `flutter run` builds and launches the app on both an iOS simulator and an Android emulator. The preview screen is visible and the theme cycle action works on both platforms. (Manual verification step performed by the user — implementation phase asks the user to confirm.) **⏳ DEFERRED — user must run manually.**
- [x] **AC-14**: No hardcoded `Color(0xFF...)` literals exist outside `lib/core/theme/`. (Grep check.)
- [x] **AC-15**: The constitution rule "no `package:flutter/*` imports in `domain/`" is not violated. (Trivially true since this spec creates no `domain/` files; checked anyway.)

## 6. Out of Scope

Explicit non-goals — these will NOT be done in this spec:

- **NOT included**: Persisting theme mode across app restarts. The `ThemeController` is in-memory only. Persistence requires a `Settings` table in drift, which is its own future feature.
- **NOT included**: Adding `flutter_riverpod` or any other state-management dependency. The theme uses a plain `ValueNotifier` to keep the spec dependency-free.
- **NOT included**: Adding `freezed`, `fpdart`, `drift`, or any constitution-Section-7.3 dependency. Those land with the features that need them.
- **NOT included**: Replacing `analysis_options.yaml` with the strict-mode version from constitution Section 7.4. That happens in a separate "infrastructure" spec to keep the diff reviewable.
- **NOT included**: Setting up `lib/core/error/`, `lib/core/database/`, `lib/core/notifications/`, `lib/core/permissions/`, `lib/core/clock/`, `lib/core/logging/`, `lib/core/routing/`. These are foundational but unrelated to theming.
- **NOT included**: Any medication/schedule/intake/adherence feature.
- **NOT included**: Any settings screen. The theme cycle action lives in the preview-screen app bar only — it's a developer affordance, not a user-facing setting.
- **NOT included**: Material Symbols (the variable-font replacement for Material Icons). The HTML uses `material-icons-round`, which maps to Flutter's built-in `Icons.xxx_rounded`. No icon font asset needed.
- **NOT included**: Localization, accessibility audits, or design-vs-implementation pixel comparison. Those happen later via the design-auditor agent.
- **NOT included**: A splash screen, app icon, or launcher graphics.
- **NOT included**: Removing or modifying the `dosly_m3_template.html` reference file. It stays in place for now.

## 7. Technical Constraints

From the constitution:

- **Section 2.2** — All theme-related code MUST live under `lib/core/theme/`. Hardcoded `Color(...)` literals outside this directory are forbidden in subsequent feature work (rule starts being enforced after this spec lands).
- **Section 4.1.1** — Always use `const` constructors when possible. Every `ColorScheme` and `ThemeData` declaration in this spec must be `const` where the API permits.
- **Section 4.2.1** — No `print()` / `debugPrint()` in committed code. The preview screen has no diagnostic logging.
- **Section 4.2.1** — No `package:flutter/*` imports in any future `domain/` directory. (Trivially satisfied — this spec creates no domain files.)
- **Section 4.3.1** — Prefer named parameters over positional. The preview screen and helper widgets use named parameters throughout.
- **Section 6.4** — Public types and methods get dartdoc (`///`) comments. `ThemeController`, `AppTheme`, `lightColorScheme`, `darkColorScheme`, `DoslyApp`, `ThemePreviewScreen` and their public APIs all get dartdoc.
- **Material 3 default**: Flutter ≥ 3.16 has `useMaterial3: true` as the default, but this spec sets it explicitly for clarity.
- **Roboto licensing**: Roboto is licensed under Apache 2.0 (Google Fonts). The downloaded `.ttf` files MUST be the official Google Fonts release. License notice goes in a `assets/fonts/LICENSE.txt` file.

## 8. Open Questions

- **Q1**: Where should the four Roboto `.ttf` files come from? Option A: download from `fonts.google.com/specimen/Roboto` (current variable font, but the four static weights are also available); Option B: copy from a known clean source. The implementation phase needs internet access OR a manual user download. **Resolution path**: implementer downloads from Google Fonts during execution; if no network, they prompt the user.
- **Q2**: The HTML uses Roboto weight 600 in a few places (e.g., line 511 `font-weight: 600`). Material 3 type scale uses 400/500 only. Should we ship weight 600 too, or treat the 600 in the HTML as a design oversight and standardize on 400/500? **Default**: skip 600 — Material 3 type scale is canonical. Note in tests.
- **Q3**: Should `ThemePreviewScreen` live under `lib/features/theme_preview/...` (treating the preview as a one-off "feature") or under `lib/core/theme/preview/`? **Default**: `lib/features/theme_preview/` — keeps `lib/core/` clean and follows the per-feature folder pattern from the constitution. The feature can be deleted later when real screens land.
- **Q4**: Should `pubspec.yaml`'s `description` field be updated as part of this spec, or is that a separate housekeeping task? **Default**: include in this spec — it's a one-line change and the current "A new Flutter project." is misleading.

These are all minor and can be resolved during `/plan` or implementation.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Roboto `.ttf` files have to be downloaded manually — implementer might use a slightly different version | Med | Low | Document the download URL (`fonts.google.com/specimen/Roboto`); commit a `assets/fonts/SOURCE.md` recording the download date and version |
| Hand-coded `ColorScheme` drifts from the HTML over time as the design changes | Med | Med | The unit test in `test/core/theme/app_color_schemes_test.dart` asserts every hex value; regenerating from a new design re-runs the same script and the test catches drift |
| `ColorScheme(...)` constructor signature changes between Flutter versions, breaking the build | Low | Med | Pin Flutter SDK version in `pubspec.yaml` (already constrained by `environment: sdk: ^3.11.1`); regenerate via `flutter create .` if structure changes |
| Theme preview screen references widgets that don't exist on iOS | Low | Low | Use only Material widgets (no Cupertino), all of which work on both platforms |
| `Icons.xxx_rounded` doesn't have a rounded variant for every icon used | Low | Low | If a particular icon lacks `_rounded`, fall back to the default; flagged during implementation |
| `font-weight: 600` mismatch between the HTML and the bundled weights causes some text to look slightly off | Low | Low | Skip 600 (per Open Question Q2); revisit if a specific screen looks wrong during /verify |
| Hot reload after main.dart rewrite loses preserved widget state | Low | Low | Hot restart instead of hot reload after the first change |
| `flutter test` fails on the new tests because the assertions are too strict and a Flutter version change adjusts default `ColorScheme` field defaults | Low | Low | Tests assert only the explicit fields we set, not derived ones |
