# Bug 004: Hand-rolled Riverpod providers; `riverpod_annotation`/`riverpod_generator` missing from pubspec

**Status**: Open
**Severity**: Critical
**Source**: audit (audits/2026-04-30-audit.md)
**Reported**: 2026-04-30
**Fixed**:

## Description

Constitution §4.1.1 [convention]: "Always use `@riverpod` codegen for new
providers. No manual `Provider`/`StateNotifierProvider` declarations."

Constitution §1 names the project's stack as "Riverpod 2.x with
`riverpod_generator` (code generation)". Yet `pubspec.yaml` does NOT list
`riverpod_annotation` (runtime) or `riverpod_generator` (dev). The agreed
idiom is missing wholesale, not just at one site.

Three providers in the codebase are hand-rolled `Provider`/`NotifierProvider`
declarations:

1. `lib/core/providers/shared_preferences_provider.dart` — `Provider<SharedPreferencesWithCache>`
2. `lib/features/settings/presentation/providers/settings_provider.dart:21` — `Provider<SettingsRepository>`
3. `lib/features/settings/presentation/providers/settings_provider.dart:28` — `NotifierProvider<SettingsNotifier, AppSettings>`

Manual providers also bypass the `autoDispose` default that codegen applies.

## File(s)

| File | Detail |
|------|--------|
| pubspec.yaml | (missing `riverpod_annotation`, `riverpod_generator`, `build_runner`) |
| lib/core/providers/shared_preferences_provider.dart | Manual Provider |
| lib/features/settings/presentation/providers/settings_provider.dart | Lines 21, 28 (manual Provider + NotifierProvider) |

## Evidence

`lib/features/settings/presentation/providers/settings_provider.dart:21–30`:
```
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dataSource = SettingsLocalDataSource(prefs);
  return SettingsRepositoryImpl(dataSource);
});

/// Provides the current [AppSettings] and exposes mutation methods.
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
```

Reported by audit (code-reviewer F9, architect F4).

## Fix Notes

Suggested approach (to be confirmed in `/fix`):

1. `flutter pub add riverpod_annotation`
2. `flutter pub add --dev riverpod_generator build_runner`
3. Migrate all three providers to `@riverpod` annotations. Replace the
   `NotifierProvider` with `@riverpod class SettingsNotifier extends
   _$SettingsNotifier`.
4. Run `dart run build_runner build --delete-conflicting-outputs`.
5. Commit generated `.g.dart` files per constitution §2.2 ("Generated files
   sit next to their source AND are committed to the repo").

Note: this work likely happens together with bug 001 (which adds `freezed` codegen)
and bug 003 (which may switch to `AsyncNotifier`). Bundling them into one
"adopt codegen + restructure SettingsNotifier" PR makes sense.
