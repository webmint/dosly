### Task 005: Add localization keys and build Settings UI

**Agent**: mobile-engineer
**Files**:
- `lib/l10n/app_en.arb` (modify)
- `lib/l10n/app_uk.arb` (modify)
- `lib/l10n/app_de.arb` (modify)
- `lib/features/settings/presentation/widgets/theme_selector.dart` (create)
- `lib/features/settings/presentation/screens/settings_screen.dart` (modify)

**Depends on**: 004
**Blocks**: 007
**Review checkpoint**: Yes (layer boundary crossing — first presentation task after domain/data/provider chain)
**Context docs**: None

**Description**:
Add the localization strings for the Appearance section and build the Settings UI — the section subheader and `SegmentedButton<ThemeMode>` widget.

**Part 1: Localization**

Add four new keys to each ARB file:

| Key | en | uk | de |
|-----|----|----|-----|
| `settingsAppearanceHeader` | `Appearance` | `Зовнішній вигляд` | `Darstellung` |
| `settingsThemeSystem` | `System` | `Системна` | `System` |
| `settingsThemeLight` | `Light` | `Світла` | `Hell` |
| `settingsThemeDark` | `Dark` | `Темна` | `Dunkel` |

Each key needs a `@key` description entry in the English ARB file. After modifying ARB files, run `flutter gen-l10n` (or `flutter pub get` which triggers it via `generate: true` in `pubspec.yaml`).

**Part 2: ThemeSelector widget** (`theme_selector.dart`)

A `ConsumerWidget` that renders a `SegmentedButton<ThemeMode>`:
- Three `ButtonSegment<ThemeMode>` entries: `ThemeMode.system`, `ThemeMode.light`, `ThemeMode.dark`
- Labels use `context.l10n.settingsThemeSystem`, `.settingsThemeLight`, `.settingsThemeDark`
- `selected: {ref.watch(settingsProvider).themeMode}`
- `onSelectionChanged: (selection) => ref.read(settingsProvider.notifier).setThemeMode(selection.first)`
- Optional: Lucide icons per segment — `LucideIcons.sunMoon` (system), `LucideIcons.sun` (light), `LucideIcons.moon` (dark)

**Part 3: Settings screen update** (`settings_screen.dart`)

Replace the empty `SizedBox.shrink()` body with a scrollable layout:
- Make `SettingsScreen` a `ConsumerWidget` (needs `ref` for the theme selector, or keep it `StatelessWidget` if ThemeSelector handles its own ref)
- Add a `SingleChildScrollView` or `ListView` body
- Add the "Appearance" group:
  - Subheader text styled as M3 group title: `labelSmall` (or `titleSmall`) in `colorScheme.primary`, uppercase, with appropriate padding. Matches the HTML template's `.settings-group-title` pattern (12px/500 weight, primary color, uppercase, letter-spacing 0.5).
  - Below the subheader: `ThemeSelector()` widget with horizontal padding
- Keep the AppBar with title and 1-px divider unchanged

**Change details**:
- `lib/l10n/app_en.arb`: Add 4 keys + 4 `@key` descriptions
- `lib/l10n/app_uk.arb`: Add 4 keys
- `lib/l10n/app_de.arb`: Add 4 keys
- `lib/features/settings/presentation/widgets/theme_selector.dart`:
  - Import `flutter_riverpod`, `flutter/material.dart`, `l10n_extensions.dart`, `settings_provider.dart`
  - `class ThemeSelector extends ConsumerWidget`
  - Build method returns `SegmentedButton<ThemeMode>` with 3 segments
- `lib/features/settings/presentation/screens/settings_screen.dart`:
  - Update library doc comment
  - Add import for `ThemeSelector`
  - Replace `body: const SizedBox.shrink()` with scrollable body containing Appearance section
  - Add subheader text widget with M3 group title styling

**Done when**:
- [ ] All three ARB files contain `settingsAppearanceHeader`, `settingsThemeSystem`, `settingsThemeLight`, `settingsThemeDark`
- [ ] `flutter gen-l10n` (via `flutter pub get`) generates updated `AppLocalizations` with the new getters
- [ ] `lib/features/settings/presentation/widgets/theme_selector.dart` exists with `ThemeSelector` rendering `SegmentedButton<ThemeMode>`
- [ ] Settings screen displays "Appearance" subheader and the SegmentedButton below it
- [ ] `dart analyze lib/features/settings/ lib/l10n/` passes with zero issues

**Spec criteria addressed**: AC-1 (subheader), AC-2 (SegmentedButton with localized labels), AC-3 (default System selection), AC-8 (all strings localized in 3 languages)

## Contracts

### Expects
- `lib/features/settings/presentation/providers/settings_provider.dart` exports `settingsProvider` (NotifierProvider)
- `lib/l10n/l10n_extensions.dart` exports `AppLocalizationsContext` extension with `l10n` getter
- `pubspec.yaml` has `generate: true` in flutter section (ARB → generated code)

### Produces
- `lib/l10n/app_en.arb` contains keys `settingsAppearanceHeader`, `settingsThemeSystem`, `settingsThemeLight`, `settingsThemeDark`
- `lib/l10n/app_uk.arb` contains the same 4 keys with Ukrainian translations
- `lib/l10n/app_de.arb` contains the same 4 keys with German translations
- `lib/features/settings/presentation/widgets/theme_selector.dart` exports `class ThemeSelector` (ConsumerWidget) rendering `SegmentedButton<ThemeMode>`
- `lib/features/settings/presentation/screens/settings_screen.dart` contains `ThemeSelector` widget and a subheader text with `settingsAppearanceHeader`
