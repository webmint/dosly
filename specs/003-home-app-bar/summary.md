## Feature Summary: 003 — Home Screen App Bar

### What was built
Added a Material 3 top app bar to the home screen matching the HTML template design. The bar displays the app title "Dosly" with a placeholder settings icon and a subtle bottom border. The global theme was updated so all app bars use the correct `surfaceContainer` background.

### Changes
- Task 001: Update global AppBarTheme defaults — changed background to `surfaceContainer`, disabled tonal elevation tint
- Task 002: Add AppBar to HomeScreen and update tests — added AppBar with title, disabled settings icon, divider bottom border; updated widget test assertions

### Files changed
- `lib/core/theme/` — 1 file modified (app_theme.dart)
- `lib/features/home/presentation/screens/` — 1 file modified (home_screen.dart)
- `test/` — 1 file modified (widget_test.dart)

Total: 3 files changed, 25 insertions, 5 deletions

### Key decisions
- **Bottom border**: `AppBar.bottom` with `PreferredSize` + `Divider()` — leverages existing `DividerThemeData` for `outlineVariant` color
- **Scroll shadow without tint**: `surfaceTintColor: Colors.transparent` globally — matches HTML template where only shadow appears on scroll, no color shift
- **Settings icon**: `onPressed: null` (standard disabled pattern) — placeholder until settings screen ships
- **Toolbar height**: Kept Flutter default 56dp rather than forcing HTML's 64px — separate decision if needed

### Acceptance criteria
- [x] AC-1: AppBar with title "Dosly"
- [x] AC-2: Disabled settings IconButton
- [x] AC-3: 1px outlineVariant bottom border
- [x] AC-4: AppBarTheme backgroundColor = surfaceContainer
- [x] AC-5: AppBarTheme surfaceTintColor = transparent
- [x] AC-6: Body content unchanged
- [x] AC-7: Navigation to /theme-preview works
- [x] AC-8: dart analyze clean
- [x] AC-9: flutter test 79/79 pass
- [x] AC-10: flutter build apk success
- [x] AC-11: No debug artifacts
- [x] AC-12: Dartdoc on public members
- [x] AC-13: No new dependencies
