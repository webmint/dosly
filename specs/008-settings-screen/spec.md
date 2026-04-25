# Spec: Settings Screen

**Date**: 2026-04-25
**Status**: Complete
**Author**: Claude + User

## 1. Overview

Create an empty Settings screen (same pattern as MedsScreen) and wire it to the gear icon on the HomeScreen AppBar so tapping the gear navigates to `/settings`. The Settings screen is a full-screen push route (not a tab branch) with a back arrow, matching the HTML template's "SCREEN 5 — SETTINGS" layout. No controls, toggles, or settings groups are included — just the empty screen shell.

## 2. Current State

- **HomeScreen** (`lib/features/home/presentation/screens/home_screen.dart`): Has an `IconButton` with `LucideIcons.settings` in the AppBar `actions`, but `onPressed: null` (disabled). Tooltip already localized via `context.l10n.settingsTooltip`.
- **Routing** (`lib/core/routing/app_router.dart`): `StatefulShellRoute.indexedStack` with 3 branches (Home `/`, Meds `/meds`, History `/history`) plus a sibling `/theme-preview` route. No `/settings` route exists.
- **HTML design** (`dosly_m3_template.html:2469–2478`): Settings screen has an AppBar with a back-arrow icon (Lucide `arrowLeft`) and title "Налаштування". Body contains settings groups with toggles/values — all of which are **out of scope** for this feature.
- **L10n**: `settingsTooltip` key exists in all 3 locales (en/uk/de). A separate `settingsTitle` key for the AppBar title does not yet exist.
- **No `lib/features/settings/` directory** exists — must be created.

## 3. Desired Behavior

1. Tapping the gear icon on the HomeScreen AppBar navigates to a new `/settings` route.
2. The Settings screen displays:
   - An AppBar with the localized title ("Settings" / "Налаштування" / "Einstellungen").
   - A leading back button (Flutter's automatic `BackButton` via `go_router` push) that returns to the Home screen.
   - A 1-px `outlineVariant` bottom divider (same pattern as MedsScreen, HistoryScreen).
3. The body is empty (`SizedBox.shrink()`).
4. The Settings screen does NOT appear in the bottom navigation bar — it is a push route, not a shell branch.
5. Pressing the system back button or the AppBar back arrow returns to the previous screen (Home).

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Settings screen | `lib/features/settings/presentation/screens/settings_screen.dart` | Create new — empty scaffold with AppBar |
| Settings screen test | `test/features/settings/presentation/screens/settings_screen_test.dart` | Create new — widget test |
| Routing | `lib/core/routing/app_router.dart` | Add `/settings` GoRoute as sibling to the StatefulShellRoute |
| Home screen | `lib/features/home/presentation/screens/home_screen.dart` | Enable gear IconButton `onPressed` → `context.push('/settings')` |
| Home screen test | `test/features/home/presentation/screens/home_screen_test.dart` | Update to verify gear icon navigates |
| L10n (en) | `lib/l10n/app_en.arb` | Add `settingsTitle` key |
| L10n (uk) | `lib/l10n/app_uk.arb` | Add `settingsTitle` key |
| L10n (de) | `lib/l10n/app_de.arb` | Add `settingsTitle` key |
| Router test | `test/core/routing/app_router_test.dart` | Add test for `/settings` route |

## 5. Acceptance Criteria

Each criterion must be testable and unambiguous:

- [x] **AC-1**: `lib/features/settings/presentation/screens/settings_screen.dart` exists and contains a `SettingsScreen` `StatelessWidget` with a `const` constructor.
- [x] **AC-2**: `SettingsScreen` renders a `Scaffold` with an `AppBar` whose `title` is `context.l10n.settingsTitle`.
- [x] **AC-3**: The AppBar has a 1-px bottom divider (`PreferredSize` + `Divider(height: 1, thickness: 1)`) — same pattern as MedsScreen.
- [x] **AC-4**: The body is `SizedBox.shrink()`.
- [x] **AC-5**: `/settings` is registered as a `GoRoute` in `app_router.dart`, outside the `StatefulShellRoute` (sibling, like `/theme-preview`).
- [x] **AC-6**: The HomeScreen gear `IconButton.onPressed` calls `context.push('/settings')` (no longer `null`).
- [x] **AC-7**: Navigating to `/settings` and pressing back returns to the Home screen (system back or AppBar back button).
- [x] **AC-8**: `settingsTitle` l10n key exists in `app_en.arb` ("Settings"), `app_uk.arb` ("Налаштування"), `app_de.arb` ("Einstellungen").
- [x] **AC-9**: Widget test for `SettingsScreen` verifies AppBar title, divider, and empty body.
- [x] **AC-10**: `dart analyze` reports zero issues on all changed files.
- [x] **AC-11**: `flutter test` passes (all existing + new tests).
- [x] **AC-12**: `flutter build apk --debug` succeeds.

## 6. Out of Scope

- NOT included: Any settings controls, toggles, value chips, or settings groups from the HTML template
- NOT included: Settings persistence or data layer (`Settings` entity, drift table, repository)
- NOT included: Notification settings, intake window settings, or any domain logic
- NOT included: Adding Settings to the bottom navigation bar
- NOT included: Deep link handling for `/settings`

## 7. Technical Constraints

- Must follow MedsScreen/HistoryScreen pattern (same AppBar + divider structure)
- Must use `context.push('/settings')` (not `context.go`) so back navigation works — `/settings` is a push route on top of the shell, not a branch replacement
- Must use `LucideIcons.arrowLeft` is NOT needed — Flutter's `AppBar` automatically shows a `BackButton` when the route is pushed via GoRouter
- Domain layer (`lib/features/settings/domain/`) is NOT created — no domain logic exists for this feature yet
- L10n key `settingsTitle` is separate from existing `settingsTooltip` — different purpose (screen title vs icon tooltip)

## 8. Open Questions

None — the scope is deliberately minimal (empty screen + navigation wiring).

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Bottom nav visible on settings screen | Low | Medium | `/settings` is a sibling GoRoute outside the StatefulShellRoute, so the shell (and its bottom nav) won't render. Verify in test. |
| Back navigation breaks shell state | Low | Low | `context.push` preserves the shell's branch stack. The StatefulShellRoute stack is unaffected by push routes. |
