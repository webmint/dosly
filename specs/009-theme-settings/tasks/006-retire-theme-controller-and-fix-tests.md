### Task 006: Retire ThemeController and fix all tests

**Agent**: architect
**Files**:
- `lib/core/theme/theme_controller.dart` (delete)
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` (modify)
- `lib/core/routing/app_router.dart` (modify — doc comment only)
- `test/core/theme/theme_controller_test.dart` (delete)
- `test/widget_test.dart` (modify)
- `test/features/settings/presentation/screens/settings_screen_test.dart` (modify)
- `test/core/routing/app_router_test.dart` (modify)

**Depends on**: 004, 005
**Blocks**: 007
**Review checkpoint**: No
**Context docs**: None

**Description**:
Delete the `ThemeController` singleton and update all files that reference it. Also update all existing tests to work with the new `ProviderScope`-based app.

**Part 1: Delete ThemeController**
- Delete `lib/core/theme/theme_controller.dart`
- Delete `test/core/theme/theme_controller_test.dart`

**Part 2: Update ThemePreviewScreen**

`lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` currently imports `theme_controller.dart` and uses:
- `themeController.value` (line 36) — to pick the icon for the cycle button
- `themeController.cycle` (line 37) — as the `onPressed` callback

Convert to `ConsumerWidget`:
- Add `flutter_riverpod` import + `settings_provider.dart` import
- Remove `theme_controller.dart` import
- `extends ConsumerWidget`, add `WidgetRef ref` to `build()`
- Replace `themeController.value` → `ref.watch(settingsProvider).themeMode`
- Replace `themeController.cycle` → a callback that cycles through modes using `ref.read(settingsProvider.notifier).setThemeMode(nextMode)`. The cycle logic (system→light→dark→system) moves inline or into a small helper.

**Part 3: Update app_router.dart doc comment**
- Lines 24-25 reference `themeController` pattern — update doc comment to reflect the new `settingsProvider` pattern.

**Part 4: Fix widget_test.dart**

Current `test/widget_test.dart` directly accesses `themeController` singleton. Rewrite:
- Remove `import 'package:dosly/core/theme/theme_controller.dart'`
- Add `import 'package:flutter_riverpod/flutter_riverpod.dart'`
- Wrap `DoslyApp()` in `ProviderScope(overrides: [...])` using a test `SharedPreferencesWithCache` or override `settingsRepositoryProvider` with a fake
- Update theme cycle assertions to verify via the provider or via widget state, not the deleted singleton
- Keep existing navigation/rendering assertions intact where possible

**Part 5: Fix settings_screen_test.dart**

The existing test uses a plain `MaterialApp(home: SettingsScreen())` harness. After Task 005, `SettingsScreen` (or its child `ThemeSelector`) is a `ConsumerWidget` that needs a `ProviderScope`. Update the `_harness()` helper to wrap in `ProviderScope` with overridden `settingsRepositoryProvider` (or `settingsProvider` directly). Keep all existing locale-switching and AppBar-shape assertions.

**Part 6: Fix app_router_test.dart**

The router test uses `MaterialApp.router(routerConfig: appRouter, ...)` without a `ProviderScope`. After Task 004, screens in the router tree (`SettingsScreen`) require Riverpod. Wrap the `_pumpRouter` helper's `MaterialApp.router(...)` in a `ProviderScope` with overrides. All existing assertions should remain valid — only the pump helper changes.

**Change details**:
- Delete `lib/core/theme/theme_controller.dart`
- Delete `test/core/theme/theme_controller_test.dart`
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`: Convert to `ConsumerWidget`, swap `themeController` references to `settingsProvider`
- `lib/core/routing/app_router.dart`: Update doc comment on lines 24-25
- `test/widget_test.dart`: Wrap in `ProviderScope`, remove `themeController` references
- `test/features/settings/presentation/screens/settings_screen_test.dart`: Wrap `_harness` in `ProviderScope`
- `test/core/routing/app_router_test.dart`: Wrap `_pumpRouter` helper in `ProviderScope`

**Done when**:
- [ ] `lib/core/theme/theme_controller.dart` does NOT exist
- [ ] `test/core/theme/theme_controller_test.dart` does NOT exist
- [ ] No file in `lib/` or `test/` imports `theme_controller.dart` (`grep -r "theme_controller" lib/ test/` returns empty)
- [ ] `dart analyze` passes with zero issues on all changed files
- [ ] `flutter test` passes — all existing tests still pass (with updated harnesses), no regressions
- [ ] `flutter build apk --debug` succeeds

**Spec criteria addressed**: AC-9 (dart analyze clean), AC-10 (flutter test passes, no regressions), AC-11 (build succeeds)

## Contracts

### Expects
- `lib/features/settings/presentation/providers/settings_provider.dart` exports `settingsProvider` and `SettingsNotifier`
- `lib/app.dart` does NOT import `theme_controller.dart` (changed in Task 004)
- `lib/features/settings/presentation/screens/settings_screen.dart` contains `ThemeSelector` (from Task 005)
- `lib/main.dart` contains `ProviderScope` wrapping `DoslyApp` (from Task 004)

### Produces
- `lib/core/theme/theme_controller.dart` is deleted
- `test/core/theme/theme_controller_test.dart` is deleted
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` is a `ConsumerWidget` — does NOT import `theme_controller.dart`, uses `settingsProvider`
- `grep -r "theme_controller" lib/ test/` returns zero matches
- `flutter test` exits with code 0
- `flutter build apk --debug` exits with code 0
