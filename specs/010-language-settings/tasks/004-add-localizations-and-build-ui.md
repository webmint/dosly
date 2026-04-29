# Task 004: Add localizations and build LanguageSelector + Settings screen section

**Status**: Complete
**Agent**: mobile-engineer
**Files**:
- `lib/l10n/app_en.arb` (MOD)
- `lib/l10n/app_de.arb` (MOD)
- `lib/l10n/app_uk.arb` (MOD)
- `lib/l10n/app_localizations.dart` (REGEN — committed)
- `lib/l10n/app_localizations_en.dart` (REGEN — committed)
- `lib/l10n/app_localizations_de.dart` (REGEN — committed)
- `lib/l10n/app_localizations_uk.dart` (REGEN — committed)
- `lib/features/settings/presentation/widgets/language_selector.dart` (NEW)
- `lib/features/settings/presentation/screens/settings_screen.dart` (MOD)

**Depends on**: 003 (and transitively 001, 002)
**Blocks**: 005
**Context docs**: None — pattern is fully established by spec 009's `theme_selector.dart` + Appearance section
**Review checkpoint**: No (Task 003 already absorbed the convergence checkpoint)

## Description

Add three new localization keys (section header, switch title, switch subtitle) to all three ARB files, regenerate `AppLocalizations`, then build the user-facing UI: a new `LanguageSelector` widget (Switch + 3 RadioListTile rows) and a Language section on the Settings screen below the existing Appearance section.

Native language names (`English`, `Deutsch`, `Українська`) are NOT added to the ARB files — they come from `AppLanguage.nativeName` (Task 001). This is the universal language-picker convention: users see their language in its own script regardless of the currently-displayed UI language.

The `LanguageSelector` mirrors `ThemeSelector`'s exact patterns (`ConsumerWidget`, `SwitchListTile` + manual selector, `contentPadding: EdgeInsets.zero`, `onChanged: null` for the disabled state, pre-fill manual choice at toggle-OFF) but uses `RadioListTile<AppLanguage>` instead of `SegmentedButton` because Cyrillic + German names overflow equal-width segments on narrow screens.

## Change details

### ARB files

#### `lib/l10n/app_en.arb` — MOD

Append three keys (with `@key` metadata blocks) at the end of the existing JSON object. Maintain the existing JSON style (2-space indent, trailing commas off — JSON requires no trailing commas).

```json
"settingsLanguageHeader": "Language",
"@settingsLanguageHeader": {
  "description": "Section header for the language settings group on the Settings screen."
},
"settingsUseDeviceLanguage": "Use device language",
"@settingsUseDeviceLanguage": {
  "description": "Label for the switch that toggles following the device-resolved language."
},
"settingsUseDeviceLanguageSub": "Follow your device settings",
"@settingsUseDeviceLanguageSub": {
  "description": "Subtitle for the device-language switch describing what the toggle does."
}
```

#### `lib/l10n/app_de.arb` — MOD

Append three keys (no `@key` metadata blocks — translations don't repeat the metadata):

```json
"settingsLanguageHeader": "Sprache",
"settingsUseDeviceLanguage": "Sprache des Geräts verwenden",
"settingsUseDeviceLanguageSub": "Geräteeinstellungen folgen"
```

#### `lib/l10n/app_uk.arb` — MOD

```json
"settingsLanguageHeader": "Мова",
"settingsUseDeviceLanguage": "Мова пристрою",
"settingsUseDeviceLanguageSub": "Використовувати налаштування пристрою"
```

### Regeneration

Run `flutter gen-l10n` (or `flutter pub get`, which triggers gen-l10n implicitly when `flutter: { generate: true }` is set in `pubspec.yaml`). The four `app_localizations*.dart` files MUST be regenerated and committed (the `synthetic-package: false` decision means generated files live in source control). Verify the new getters appear in `app_localizations.dart`:
- `String get settingsLanguageHeader;`
- `String get settingsUseDeviceLanguage;`
- `String get settingsUseDeviceLanguageSub;`

If `flutter gen-l10n` produces unrelated diffs (e.g., reordered cases), inspect carefully before staging.

### `lib/features/settings/presentation/widgets/language_selector.dart` — CREATE

Pattern: mirror `lib/features/settings/presentation/widgets/theme_selector.dart` exactly in shape, swap the SegmentedButton for a RadioListTile list. Full skeleton:

```dart
/// Settings feature — language-selector widget.
///
/// Exports [LanguageSelector], a [ConsumerWidget] that renders a
/// [SwitchListTile] for the "Use device language" toggle and a list of
/// [RadioListTile] rows (one per [AppLanguage]) for the manual language
/// override. State is read from and written to [settingsProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../domain/entities/app_language.dart';
import '../providers/settings_provider.dart';

/// A compound widget that lets the user control the app language.
///
/// Contains:
/// - A [SwitchListTile] labelled "Use device language". When ON the device
///   language drives [MaterialApp.locale]. When OFF the radio list below
///   becomes interactive.
/// - Three [RadioListTile] rows iterated from [AppLanguage.values], each
///   showing the language's native name. Disabled — but still showing the
///   current selection — while the toggle is ON.
///
/// When the user turns the toggle OFF, [manualLanguage] is pre-filled with
/// the language matching the current device locale (or [AppLanguage.en] when
/// the device locale is unsupported) so the transition feels seamless.
class LanguageSelector extends ConsumerWidget {
  /// Creates the language selector widget.
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(l10n.settingsUseDeviceLanguage),
          subtitle: Text(l10n.settingsUseDeviceLanguageSub),
          value: settings.useSystemLanguage,
          contentPadding: EdgeInsets.zero,
          onChanged: (bool value) {
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
            ref.read(settingsProvider.notifier).setUseSystemLanguage(value);
          },
        ),
        const SizedBox(height: 8),
        for (final language in AppLanguage.values)
          RadioListTile<AppLanguage>(
            title: Text(language.nativeName),
            value: language,
            groupValue: settings.manualLanguage,
            contentPadding: EdgeInsets.zero,
            onChanged: settings.useSystemLanguage
                ? null
                : (AppLanguage? selected) {
                    if (selected != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .setManualLanguage(selected);
                    }
                  },
          ),
      ],
    );
  }
}
```

Key constitution-compliance points:
- No `!` null assertion. The `RadioListTile.onChanged`'s `AppLanguage?` is null-checked with an `if (selected != null)` (mirror of the theme selector's branch handling).
- `Localizations.localeOf(context)` is read synchronously at the top of `onChanged` — the value is stored in a local before any `await`-adjacent code, so there's no `mounted` hazard.
- `EdgeInsets.zero` on every list-tile `contentPadding` because the parent `Padding` (in `SettingsScreen`) supplies the 16-px horizontal inset.

### `lib/features/settings/presentation/screens/settings_screen.dart` — MOD

Inside the existing `ListView`'s `children:` list, after the existing Appearance section's two `Padding` entries, append a parallel pair for the Language section. The Language header `Text` style and `Padding` insets are identical to the Appearance header:

```dart
// Language group
Padding(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
  child: Text(
    context.l10n.settingsLanguageHeader.toUpperCase(),
    style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
  ),
),
const Padding(
  padding: EdgeInsets.symmetric(horizontal: 16),
  child: LanguageSelector(),
),
```

Add `import '../widgets/language_selector.dart';` next to the existing `theme_selector.dart` import.

The library-level dartdoc may receive a one-line mention of the Language section.

## Done when

- [x] All three ARB files contain keys `settingsLanguageHeader`, `settingsUseDeviceLanguage`, `settingsUseDeviceLanguageSub`. The English file includes `@key` metadata blocks for all three; the German and Ukrainian files do not.
- [x] `lib/l10n/app_localizations.dart` and the three locale-specific generated files have been regenerated and expose getters `settingsLanguageHeader`, `settingsUseDeviceLanguage`, `settingsUseDeviceLanguageSub`.
- [x] `lib/features/settings/presentation/widgets/language_selector.dart` exists and exports `class LanguageSelector extends ConsumerWidget`.
- [x] The widget renders `SwitchListTile` and three `RadioListTile<AppLanguage>` instances iterated from `AppLanguage.values`.
- [x] `RadioListTile.onChanged` uses an `if (selected != null)` null-check (no `!` null-assertion).
- [x] `SwitchListTile.onChanged` reads `Localizations.localeOf(context).languageCode` synchronously before calling notifier methods and pre-fills `manualLanguage` BEFORE flipping `useSystemLanguage` to `false`.
- [x] `lib/features/settings/presentation/screens/settings_screen.dart`'s `ListView` includes a `Text(context.l10n.settingsLanguageHeader.toUpperCase(), ...)` header followed by a `LanguageSelector` widget, both wrapped in `Padding`s with the documented insets.
- [x] `dart analyze` exits with zero issues on all changed files.

## Spec criteria addressed

AC-8, AC-9, AC-10.

## Completion Notes

**Completed**: 2026-04-27
**Files changed**:
- `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (MOD — 3 new keys each)
- `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` (REGEN, committed)
- `lib/features/settings/presentation/widgets/language_selector.dart` (NEW)
- `lib/features/settings/presentation/screens/settings_screen.dart` (MOD)

**Contract**: Expects 6/6 verified | Produces 7/7 verified

**Notes**:
- **API migration discovery**: Flutter 3.32+ deprecated `RadioListTile.groupValue` and `RadioListTile.onChanged` in favour of a `RadioGroup<T>` ancestor pattern. The plan specified the older API; the agent first attempted to suppress with `// ignore_for_file: deprecated_member_use` (rejected per MEMORY.md Feature-002 lint-suppression lesson) and then migrated to the new pattern in a repair pass.
  - **Final shape**: `RadioGroup<AppLanguage>` ancestor owns `groupValue` and `onChanged`. Each `RadioListTile<AppLanguage>` retains `title`, `value`, `contentPadding` and adds `enabled: !settings.useSystemLanguage` for the disabled state (because `RadioGroup.onChanged` is non-nullable, disabled-via-null isn't an option at the group level).
  - **Implication for Task 005 widget tests**: the planned assertion `expect(tile.onChanged, isNull)` for the system-on case must instead be `expect(tile.enabled, isFalse)`. Spec AC-11 ("when system ON, all radios are non-interactive") is still satisfied — the mechanism is now `enabled`, not `onChanged: null`.
- `dart analyze lib/` exits zero. No `// ignore` / `// ignore_for_file` directives in any new code.
- Native names (`English`, `Deutsch`, `Українська`) live as `AppLanguage.nativeName` literals — never localized.
- Pre-fill at toggle-OFF reads `Localizations.localeOf(context).languageCode` synchronously into a local before the first `await`, then calls `setManualLanguage(pre)` BEFORE `setUseSystemLanguage(false)` (D7 ordering preserved).
- Per-task code-reviewer skipped: convergence checkpoint already cleared at Task 003; aggregate review will run during `/review`.

## Contracts

### Expects
- `SettingsNotifier.setUseSystemLanguage(bool)` and `SettingsNotifier.setManualLanguage(AppLanguage)` exist (Task 003 → Produces).
- `MaterialApp.router.locale` reads `effectiveLocale` (Task 003 → Produces).
- `AppLanguage.values` exposes `en`, `de`, `uk`, each with `code` and `nativeName` (Task 001 → Produces).
- Existing `lib/features/settings/presentation/screens/settings_screen.dart` declares the Appearance group with the documented header style and padding insets (current codebase state).
- Existing `lib/l10n/l10n_extensions.dart` exports `BuildContext.l10n` getter (current codebase state).
- `pubspec.yaml`'s `flutter:` section declares `generate: true` (current codebase state from spec 006).

### Produces
- `lib/l10n/app_en.arb` JSON object contains string keys `settingsLanguageHeader` (`"Language"`), `settingsUseDeviceLanguage` (`"Use device language"`), `settingsUseDeviceLanguageSub` (`"Follow your device settings"`), each accompanied by an `@key` metadata block with a `description`.
- `lib/l10n/app_de.arb` contains the same keys with values `"Sprache"`, `"Sprache des Geräts verwenden"`, `"Geräteeinstellungen folgen"`.
- `lib/l10n/app_uk.arb` contains the same keys with values `"Мова"`, `"Мова пристрою"`, `"Використовувати налаштування пристрою"`.
- `lib/l10n/app_localizations.dart` declares abstract getters `String get settingsLanguageHeader`, `String get settingsUseDeviceLanguage`, `String get settingsUseDeviceLanguageSub`.
- `lib/features/settings/presentation/widgets/language_selector.dart` exports `class LanguageSelector extends ConsumerWidget`.
- `LanguageSelector.build` produces a `Column` containing one `SwitchListTile` and three `RadioListTile<AppLanguage>` widgets (one per `AppLanguage.values` entry).
- `lib/features/settings/presentation/screens/settings_screen.dart` imports `'../widgets/language_selector.dart'` and renders a `LanguageSelector` widget inside the screen's `ListView`.
