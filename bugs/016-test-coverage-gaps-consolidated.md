# Bug 016: Consolidated test-coverage gaps (10 sub-items)

**Status**: Open
**Severity**: Warning
**Source**: audit (audits/2026-04-30-audit.md)
**Reported**: 2026-04-30
**Fixed**:

## Description

The audit's qa-engineer pass identified 10 logic-blind-spots — branches in
business-logic code with no test exercising them. Three of these are
recurring gaps from prior specs (008 and 010). They are consolidated into one
bug here so a single test-hardening PR can close all 10 in one pass.

## File(s)

| File | Detail |
|------|--------|
| lib/features/settings/data/datasources/settings_local_data_source.dart | Sub-items 1, 2, 10 (no dedicated test file) |
| lib/features/home/presentation/screens/home_screen.dart | Sub-item 3 (no `home_screen_test.dart`) |
| lib/features/settings/domain/entities/app_settings.dart | Sub-item 4 (no `app_settings_test.dart`) |
| lib/features/theme_preview/presentation/screens/theme_preview_screen.dart | Sub-items 5, 6 |
| lib/features/settings/data/repositories/settings_repository_impl.dart | Sub-item 7 |
| lib/features/settings/presentation/widgets/language_selector.dart | Sub-item 8 |
| lib/app.dart | Sub-item 9 (`_resolveLocale`) |
| test/features/settings/data/datasources/ | (does not exist — sub-item 10) |

## Evidence

Sub-items (each with file:line + verbatim evidence in the audit report):

1. **`settings_local_data_source.dart:38`** — Negative-index branch in
   `getThemeMode()` untested (`{'themeMode': -1}` not exercised).
2. **`settings_local_data_source.dart:67`** — Empty-string `''` in
   `getManualLanguage()` untested. Spec-010 gap, still open.
3. **`home_screen.dart:41`** — Gear-icon tap navigation never exercised
   end-to-end. No `home_screen_test.dart` exists. `app_router_test.dart` Test 6
   pushes `/settings` programmatically, not via the gear. Spec-008 gap, still open.
4. **`app_settings.dart:72`** — `copyWith` not unit-tested in isolation. Spec-010
   gap, still open. `??`-on-each-field invariant only implicitly verified.
5. **`theme_preview_screen.dart:23`** — `_iconForEffectiveMode` icon-selection
   not asserted. Swapping `LucideIcons.sun` ↔ `LucideIcons.sunMoon` would not
   be caught.
6. **`theme_preview_screen.dart:43`** — `manualThemeMode == ThemeMode.system`
   defensive cycle branch untested.
7. **`settings_repository_impl.dart:30`** — Exception-catch path never tested
   for any of the 4 save methods. Constitution §3.2 invariant
   ("exceptions never escape data layer") entirely unverified. Pairs with bug
   010.
8. **`language_selector.dart:81`** — `selected == null` defensive guard in
   `DropdownButton.onChanged` untested.
9. **`app.dart:32`** — `_resolveLocale` `null deviceLocale` branch untested;
   same function duplicated × 4 across test harnesses.
10. **`settings_local_data_source.dart`** — No dedicated test file. Constitution
    §3.4 mandates `test/` mirror per source file with business logic.

Reported by audit (qa-engineer F2, F3, F4, F5, F6, F7, F8, F9, F10, F11).

## Fix Notes

Suggested approach (to be confirmed in `/fix` via the `qa-engineer` agent):

1. Create `test/features/settings/data/datasources/settings_local_data_source_test.dart`
   covering all six public methods including negative-index, empty-string,
   `null`-key, and out-of-range fallbacks. (Closes sub-items 1, 2, 10.)
2. Create `test/features/home/presentation/screens/home_screen_test.dart` with
   a `MaterialApp.router` harness, tap `find.byTooltip(...)`, assert
   `find.byType(SettingsScreen)`. (Closes sub-item 3.)
3. Create `test/features/settings/domain/entities/app_settings_test.dart` with
   all-null `copyWith`, each-field-individually, `effectiveThemeMode` and
   `effectiveLocale` getters across both `useSystemX=true/false` branches.
   (Closes sub-item 4.)
4. Extend `widget_test.dart` to assert `find.byIcon(LucideIcons.sun/.sunMoon/.moon)`
   for each cycle step. (Closes sub-item 5.)
5. Add a test pre-seeding `AppSettings(useSystemTheme: false, manualThemeMode:
   ThemeMode.system)`, tap cycle, assert `useSystemTheme` becomes `true`.
   (Closes sub-item 6.)
6. Introduce a `_FailingDataSource` test double; add 4 tests asserting
   `Left<Failure, void>` for each save method. (Closes sub-item 7. Pairs with
   bug 010.)
7. Document or remove the `if (selected != null)` guard in `language_selector
   .dart`'s `DropdownButton.onChanged`. (Closes sub-item 8.)
8. Extract `_resolveLocale` from `app.dart` to
   `lib/core/utils/locale_resolver.dart` (public function), add direct unit
   tests for both branches, eliminate the 4-way duplication in test harnesses.
   (Closes sub-item 9.)

Some sub-items are downstream of structural fixes — sub-items 4, 5, 6 in
particular may need updating after bug 001's `AppThemeMode` migration. Best
ordering: land bugs 001/004/006 first, then 016.
