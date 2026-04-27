# Research: Theme Settings

**Date**: 2026-04-25
**Signals detected**: `shared_preferences` (new dep), `flutter_riverpod` (new dep — first Riverpod usage)

## Questions Investigated

1. **Modern SharedPreferences API for blocking init** → `SharedPreferencesWithCache.create()` in `main()` provides async init + synchronous reads. The legacy `SharedPreferences.getInstance()` is deprecated. `SharedPreferencesWithCacheOptions(allowList:)` restricts keys for safety.

2. **Riverpod pattern for pre-seeded state** → `ProviderScope(overrides: [provider.overrideWithValue(value)])` seeds a provider before any widget reads it. Combined with `SharedPreferencesWithCache` init in `main()`, the settings provider starts with the persisted value — no `AsyncValue` loading state needed.

3. **M3 SegmentedButton API** → `SegmentedButton<T>` takes `segments: List<ButtonSegment<T>>`, `selected: Set<T>`, `onSelectionChanged: ValueChanged<Set<T>>`. Single-selection by default (`multiSelectionEnabled: false`). Fully themed by `ThemeData.segmentedButtonTheme` and inherits `ColorScheme` tokens.

4. **Codegen stack (freezed + riverpod_generator) for this feature?** → Neither `freezed` nor `riverpod_generator` nor `build_runner` are installed. Adding the full codegen stack for a one-field settings class is disproportionate. Hand-written `Notifier` and immutable class are sufficient. Codegen will be adopted when the first data-heavy feature (medications/intakes) ships.

## References
- SharedPreferencesWithCache: https://pub.dev/packages/shared_preferences
- Riverpod overrides: https://github.com/rrousselgit/riverpod/blob/master/website/docs/concepts2/overrides.mdx
- SegmentedButton migration: https://github.com/flutter/website/blob/main/src/content/release/breaking-changes/material-3-migration.md
