# Bug 009: Cross-feature import in `theme_preview_screen.dart`

**Status**: Open
**Severity**: Warning
**Source**: audit (audits/2026-04-30-audit.md)
**Reported**: 2026-04-30
**Fixed**:

## Description

Constitution §2.1 (Cross-feature rules): "A widget in `features/A/presentation/`
may NOT import from `features/B/`. If feature A needs feature B's data, expose
it through a `domain/` interface in `lib/core/` or via the public domain API of
B."

`lib/features/theme_preview/presentation/screens/theme_preview_screen.dart:14`
imports `settingsProvider` directly from `lib/features/settings/presentation/providers/`
— the deepest, most volatile layer of another feature. The screen also writes
to it (`notifier.setThemeMode(...)`, `notifier.setUseSystemTheme(...)`),
creating bidirectional coupling between two unrelated features.

The comment self-acknowledges the violation as "temporary" but the constitution
carves out no temporary-OK exception. Worse, any future Settings refactor (e.g.
the bug 005 use-case migration) breaks `theme_preview_screen.dart` even though
it's "scheduled for removal."

## File(s)

| File | Detail |
|------|--------|
| lib/features/theme_preview/presentation/screens/theme_preview_screen.dart | Lines 12–14 (cross-feature import) |
| lib/core/routing/app_router.dart | Lines 61–66 (matching `TODO(post-mvp): remove this route`) |
| lib/features/home/presentation/screens/home_screen.dart | Lines 58–64 (matching `TODO(post-mvp): remove this dev entry point`) |

## Evidence

`lib/features/theme_preview/presentation/screens/theme_preview_screen.dart:12–14`:
```
// Temporary cross-feature import — ThemePreviewScreen is a dev-only screen
// scheduled for removal (see specs/002-main-screen/spec.md §6 and §8).
import '../../../settings/presentation/providers/settings_provider.dart';
```

Reported by audit (code-reviewer F11, architect F7).

## Fix Notes

Two options (to be confirmed in `/fix`):

**Option A (preferred — execute the scheduled removal):** delete
`lib/features/theme_preview/` entirely along with the matching `/theme-preview`
route in `app_router.dart` and the "Theme preview" button in `home_screen.dart`.
The constitution rule violation goes away with the file. Scope is well-defined
and the TODOs already exist for it.

**Option B (if the preview is still useful):** replace the live binding with a
self-contained local `ValueNotifier<ThemeMode>` whose only effect is local —
the preview screen demonstrates theming without hooking into real app state.
~10 lines, removes the layering violation immediately.

Spec 002 is the originating spec for this — confirm with the user whether the
preview screen still has development utility before deleting.
