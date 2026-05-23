# Task 003: Build splash and prefs-load-error widgets

**Agent**: mobile-engineer
**Files**: `lib/core/widgets/splash_screen.dart` (new), `lib/core/widgets/prefs_load_error_screen.dart` (new)
**Depends on**: 001
**Blocks**: 004
**Context docs**: None
**Review checkpoint**: No
**Status**: Complete

## Description

Create the two presentation widgets `AppBootstrap` (Task 004) renders during the loading and error phases. Both are stateless, localized via `context.l10n`, and follow the existing `_RouterErrorScreen` pattern in `lib/core/routing/app_router.dart` (centered Column, `FilledButton` recovery action). No wiring into the app here — these are pure widgets verified by Task 004.

- **`SplashScreen`** — fills the viewport with `Theme.of(context).colorScheme.surface`, centers a `CircularProgressIndicator` plus the `context.l10n.splashLoading` label. The surface background matches the native OS launch screen so the hand-off is seamless.
- **`PrefsLoadErrorScreen`** — centered `context.l10n.prefsLoadErrorMessage` text plus a `FilledButton` labelled `context.l10n.prefsLoadRetry` that invokes a required `VoidCallback onRetry`. The widget itself does not know about providers — the retry behavior is injected by the caller (Task 004), keeping the widget testable in isolation.

## Change details

- Create `lib/core/widgets/splash_screen.dart`:
  - `class SplashScreen extends StatelessWidget` with `const SplashScreen({super.key})`.
  - `build`: `Scaffold(backgroundColor: Theme.of(context).colorScheme.surface, body: Center(child: Column(mainAxisSize: min, children: [CircularProgressIndicator(), SizedBox, Text(context.l10n.splashLoading)])))`.
  - Public dartdoc on the class.
- Create `lib/core/widgets/prefs_load_error_screen.dart`:
  - `class PrefsLoadErrorScreen extends StatelessWidget` with `final VoidCallback onRetry;` and `const PrefsLoadErrorScreen({required this.onRetry, super.key})`.
  - `build` mirrors `_RouterErrorScreen`: `Scaffold` → padded centered `Column` → `Text(context.l10n.prefsLoadErrorMessage, textAlign: center)` → `SizedBox` → `FilledButton(onPressed: onRetry, child: Text(context.l10n.prefsLoadRetry))`.
  - Public dartdoc on the class and the `onRetry` field.
- Import `package:flutter/material.dart` and the `context.l10n` extension (`package:dosly/l10n/l10n_extensions.dart` or the matching relative path).

## Contracts

### Expects
- `lib/l10n/app_localizations.dart` declares `String get splashLoading`, `String get prefsLoadErrorMessage`, `String get prefsLoadRetry` (Task 001).
- `lib/l10n/l10n_extensions.dart` provides the `context.l10n` getter returning `AppLocalizations`.

### Produces
- `lib/core/widgets/splash_screen.dart` declares `class SplashScreen extends StatelessWidget`; its `build` uses `Theme.of(context).colorScheme.surface`, a `CircularProgressIndicator`, and `context.l10n.splashLoading`.
- `lib/core/widgets/prefs_load_error_screen.dart` declares `class PrefsLoadErrorScreen extends StatelessWidget` with a `final VoidCallback onRetry`; its `build` uses `context.l10n.prefsLoadErrorMessage`, a `FilledButton` whose `onPressed` is `onRetry`, and `context.l10n.prefsLoadRetry`.

## Done when
- [x] `SplashScreen` renders a progress indicator on a `colorScheme.surface` background with the localized loading label.
- [x] `PrefsLoadErrorScreen` exposes a required `onRetry` callback wired to the `FilledButton`, with localized message + retry label.
- [x] Neither widget references any provider (no Riverpod imports).
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-5, AC-7

## Completion Notes
**Completed**: 2026-05-23
**Files changed**: lib/core/widgets/splash_screen.dart (new), lib/core/widgets/prefs_load_error_screen.dart (new)
**Contract**: Expects [2/2 verified] | Produces [2/2 verified]
**Notes**: Provider-agnostic widgets (no Riverpod) — onRetry is a plain VoidCallback injected by the caller. Error screen mirrors _RouterErrorScreen layout. Code review done inline (trivial layout, mirrors reviewed pattern) — APPROVE.
