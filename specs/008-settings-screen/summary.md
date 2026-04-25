## Feature Summary: 008 — Settings Screen

### What was built
An empty Settings screen accessible from the gear icon on the HomeScreen AppBar. Tapping the gear pushes a `/settings` route that displays a localized title, a back button (automatic via GoRouter push), and a 1-px divider — matching the visual pattern of the Meds and History screens. No settings controls are included; this is the shell for future settings UI.

### Changes
- Task 1: Create Settings screen, l10n keys, route, and gear icon wiring — added `SettingsScreen` widget, registered `/settings` GoRoute, enabled the gear icon with `context.push('/settings')`, added `settingsTitle` l10n key in en/uk/de
- Task 2: Add tests — 6 widget tests for SettingsScreen (locale switching + AppBar shape) and 1 router integration test (push/pop round-trip without bottom nav)

### Files changed
- `lib/features/settings/` — 1 file added (settings_screen.dart)
- `lib/core/routing/` — 1 file modified (app_router.dart)
- `lib/features/home/` — 1 file modified (home_screen.dart)
- `lib/l10n/` — 6 files modified (3 ARB + 3 auto-generated)
- `test/` — 1 file added (settings_screen_test.dart), 1 modified (app_router_test.dart)
- Total: 11 source files changed, +659 insertions, -33 deletions (bulk is spec artifacts)

### Key decisions
- **Sibling GoRoute, not shell branch**: `/settings` is a push route outside the `StatefulShellRoute` — no bottom nav on the settings screen, back navigation preserves shell state
- **Separate l10n key**: `settingsTitle` is distinct from `settingsTooltip` to allow future divergence between screen title and icon tooltip
- **No manual back button**: Flutter's `AppBar` auto-shows a `BackButton` on pushed routes — no `leading:` override needed

### Acceptance criteria
- [x] AC-1: SettingsScreen exists with const constructor
- [x] AC-2: AppBar title uses context.l10n.settingsTitle
- [x] AC-3: 1-px bottom divider (PreferredSize + Divider)
- [x] AC-4: Body is SizedBox.shrink()
- [x] AC-5: /settings registered outside StatefulShellRoute
- [x] AC-6: Gear icon calls context.push('/settings')
- [x] AC-7: Back navigation returns to Home
- [x] AC-8: settingsTitle l10n key in en/uk/de
- [x] AC-9: Widget tests verify title, divider, AppBar shape
- [x] AC-10: dart analyze clean
- [x] AC-11: flutter test 112/112 pass
- [x] AC-12: flutter build apk --debug succeeds
