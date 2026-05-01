# Bug 005: Settings feature has no `domain/usecases/`; business rules duplicated in widgets

**Status**: Open
**Severity**: Critical
**Source**: audit (audits/2026-04-30-audit.md)
**Reported**: 2026-04-30
**Fixed**:

## Description

Constitution §2.1 mandates `domain/usecases/`: "single-purpose callable
classes; one operation per class. Always return `Future<Either<Failure, T>>`."
§4.1.1: "Screens never call repositories directly."

`SettingsNotifier` invokes `SettingsRepositoryImpl` directly through the
repository contract — no use case exists. There is no
`lib/features/settings/domain/usecases/` directory.

The cross-cutting rule "switching to manual must pre-fill the matching device
language/theme" is duplicated across three widget files instead of living in a
use case:

- `lib/features/settings/presentation/widgets/language_selector.dart` — pre-fill
  on toggle-off (lines 60–69) AND device-language resolution in `build`
  (lines 41–47)
- `lib/features/settings/presentation/widgets/theme_selector.dart` — equivalent
  pre-fill logic for `ThemeMode`
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`
  — cycle logic that duplicates parts of the same rule

Three occurrences crosses the constitution §3.6 DRY threshold ("If the same
logic appears in 3+ places, extract it"). Worse, the rule lives in widget code
— exactly where business logic is supposed not to live.

## File(s)

| File | Detail |
|------|--------|
| lib/features/settings/domain/usecases/ | (does not exist) |
| lib/features/settings/presentation/providers/settings_provider.dart | Notifier calls repo directly |
| lib/features/settings/presentation/widgets/language_selector.dart | Lines 41–47, 60–69 (pre-fill rule duplicated) |
| lib/features/settings/presentation/widgets/theme_selector.dart | Equivalent pre-fill logic |
| lib/features/theme_preview/presentation/screens/theme_preview_screen.dart | Cycle logic duplicates parts of the rule |

## Evidence

`lib/features/settings/presentation/providers/settings_provider.dart:48–50`:
```
  Future<void> setThemeMode(ThemeMode mode) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.saveThemeMode(mode);
```
(Notifier reaches directly into the repository.)

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

Reported by audit (architect F5, language-selector duplicates flagged by
code-reviewer F10 / architect F10).

## Fix Notes

Suggested approach (to be confirmed in `/fix`):

1. Create `lib/features/settings/domain/usecases/`:
   - `set_theme_mode.dart`
   - `set_use_system_theme.dart` (pre-fills the matching device theme on toggle-off)
   - `set_use_system_language.dart` (pre-fills the matching device language on toggle-off)
   - `set_manual_language.dart`
2. Each use case is a callable class returning `Future<Either<Failure, void>>`.
3. Move the pre-fill logic out of `language_selector.dart` and `theme_selector.dart`
   into the relevant use case so a single test covers the invariant.
4. Add a `AppLanguage.fromLanguageCodeOrDefault(String code)` static helper
   (pure-Dart, in the entity file) to absorb the repeated `firstWhere(orElse:
   AppLanguage.en)` literal across the codebase.
5. Notifier calls use cases via Riverpod providers (codegen — pairs with bug 004).

Bundles with bugs 001 (which gives the use cases a clean `AppThemeMode` to work
with), 003 (which restructures the notifier), and 004 (codegen). Reasonable
to land in a single Settings-refactor PR.
