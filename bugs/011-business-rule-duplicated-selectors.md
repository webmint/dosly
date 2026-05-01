# Bug 011: Business-rule duplication × 3 across `language_selector` / `theme_selector` / `theme_preview_screen`

**Status**: Open
**Severity**: Warning
**Source**: audit (audits/2026-04-30-audit.md)
**Reported**: 2026-04-30
**Fixed**:

## Description

The "system-X + manual-X" picker pattern — display device-resolved value when
toggle is ON, pre-fill matching device value when toggle flips OFF — is
duplicated across three widget files. Constitution §3.6 DRY: "If the same
logic appears in 3+ places, extract it." Constitution §4.1.1 also says
business logic shouldn't live in widgets.

Three sites:

1. `lib/features/settings/presentation/widgets/language_selector.dart`:
   - `build` lines 41–47 (compute `displayedLanguage` from device locale + fallback)
   - `onChanged` lines 60–69 (pre-fill on toggle-off — same `firstWhere(orElse: AppLanguage.en)`)
2. `lib/features/settings/presentation/widgets/theme_selector.dart`: equivalent
   logic for `ThemeMode`.
3. `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`:
   cycle logic that conditionally calls `setUseSystemTheme(true)` and reads the
   same effective-mode resolution.

Inside `language_selector.dart` alone the device-language lookup is computed
twice per `build()` — once for `displayedLanguage`, once again inside
`onChanged`. That's the same lookup running on every rebuild.

This bug will be largely subsumed by bug 005 (use case extraction) — but it
can also land as a smaller, independent refactor: extract a static helper on
the domain enum, dedup the `build`/`onChanged` paths in each selector.

## File(s)

| File | Detail |
|------|--------|
| lib/features/settings/presentation/widgets/language_selector.dart | Lines 41–47, 60–69 (twice in same file) |
| lib/features/settings/presentation/widgets/theme_selector.dart | Equivalent pattern for ThemeMode |
| lib/features/theme_preview/presentation/screens/theme_preview_screen.dart | Lines 33–34, 43–57 (cycle logic) |
| lib/features/settings/domain/entities/app_language.dart | (helper to add: `fromLanguageCodeOrDefault`) |

## Evidence

`lib/features/settings/presentation/widgets/language_selector.dart:38–47`:
```
    // When the system toggle is active, derive the displayed entry from the
    // actual device-resolved locale so the user can see what the system is
    // using — not the stale prior manual selection.
    final deviceCode = Localizations.localeOf(context).languageCode;
    final deviceLanguage = AppLanguage.values.firstWhere(
      (lang) => lang.code == deviceCode,
      orElse: () => AppLanguage.en,
    );
    final displayedLanguage =
        settings.useSystemLanguage ? deviceLanguage : settings.manualLanguage;
```

`lib/features/settings/presentation/widgets/language_selector.dart:60–69`:
```
            if (!value) {
              // Switching to manual — pre-fill the matching device language
              // so the visible UI doesn't lurch to a different language.
              final deviceCode =
                  Localizations.localeOf(context).languageCode;
              final pre = AppLanguage.values.firstWhere(
                (lang) => lang.code == deviceCode,
                orElse: () => AppLanguage.en,
              );
              ref.read(settingsProvider.notifier).setManualLanguage(pre);
            }
```

Reported by audit (code-reviewer F10, architect F10).

## Fix Notes

Suggested approach (to be confirmed in `/fix`):

1. Add `static AppLanguage AppLanguage.fromLanguageCodeOrDefault(String code)`
   on the enum (pure-Dart, in `lib/features/settings/domain/entities/app_language.dart`).
2. Add the equivalent `static AppThemeMode AppThemeMode.fromBrightness(...)`
   helper after bug 001 introduces the domain enum.
3. In each selector's `build`, compute `deviceLanguage` once into a local var
   and reuse it inside `onChanged` via closure capture (single source of truth
   per build).
4. Once bug 005 lands, the pre-fill behavior moves into the `SetUseSystemX`
   use case and the widget callback simplifies to a single use-case invocation.

Note: this bug is **subsumed** by bug 005 if 005 is fixed first. If a smaller,
independent refactor is preferred (e.g. for a quick lint-clean PR before the
bigger Settings restructure), this bug stands alone.
