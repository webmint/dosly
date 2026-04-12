# Task 002: Add AppBar to HomeScreen and update tests

**Agent**: mobile-engineer
**Files**: `lib/features/home/presentation/screens/home_screen.dart`, `test/widget_test.dart`
**Depends on**: 001
**Blocks**: None
**Context docs**: None
**Review checkpoint**: Yes

## Description

Add a Material 3 `AppBar` to the `HomeScreen` scaffold matching the HTML template's `.app-bar` for the home screen. The AppBar has:

- **Title**: `Text('Dosly')` — inherits `titleLarge` style and left-alignment from the global `AppBarTheme` (updated in Task 001).
- **Actions**: Single `IconButton` with `Icons.settings` icon. `onPressed: null` (disabled placeholder — no settings screen exists yet). Include `tooltip: 'Settings'` for accessibility.
- **Bottom border**: Use `AppBar.bottom` with `PreferredSize(preferredSize: Size.fromHeight(1), child: Divider())`. The global `DividerThemeData` already configures `color: outlineVariant`, `space: 1`, `thickness: 1`, so a bare `Divider()` renders the correct 1px line.

The existing body content (`Center > Column > [Text('Hello World'), SizedBox, OutlinedButton]`) must remain byte-for-byte unchanged. Only add the `appBar:` parameter to `Scaffold`.

Update `HomeScreen`'s class-level dartdoc to describe the AppBar (title, placeholder settings icon, bottom border).

Also update the first widget test in `test/widget_test.dart` to assert the AppBar title is present.

## Change details

- In `lib/features/home/presentation/screens/home_screen.dart`:
  - Update the class-level dartdoc (`///` comments) to describe the AppBar: app title "Dosly", disabled settings gear icon placeholder, `outlineVariant` bottom border
  - In `build()`, add `appBar:` parameter to `Scaffold` before `body:`:
    ```dart
    appBar: AppBar(
      title: const Text('Dosly'),
      actions: [
        IconButton(
          onPressed: null,
          tooltip: 'Settings',
          icon: const Icon(Icons.settings),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(),
      ),
    ),
    ```
  - Body content (`Center(child: Column(...))`) stays unchanged

- In `test/widget_test.dart`:
  - In the first test (`'DoslyApp renders the home screen...'`), add after the existing assertions:
    ```dart
    expect(find.text('Dosly'), findsOneWidget);
    ```
  - Rename the test to include "app bar" context, e.g.: `'DoslyApp renders the home screen with app bar, Hello World, and Theme preview button'`
  - No changes to the second test (navigation + theme cycling)

## Contracts

### Expects
- `lib/core/theme/app_theme.dart` contains `backgroundColor: scheme.surfaceContainer,` inside `AppBarTheme(` (produced by Task 001)
- `lib/core/theme/app_theme.dart` contains `surfaceTintColor: Colors.transparent,` inside `AppBarTheme(` (produced by Task 001)
- `lib/features/home/presentation/screens/home_screen.dart` contains `Scaffold(` with `body:` and no `appBar:` parameter
- `test/widget_test.dart` contains `expect(find.text('Hello World'), findsOneWidget)`

### Produces
- `lib/features/home/presentation/screens/home_screen.dart` contains `appBar: AppBar(` with `title: const Text('Dosly')`
- `lib/features/home/presentation/screens/home_screen.dart` contains `IconButton(` with `onPressed: null` and `icon: const Icon(Icons.settings)`
- `lib/features/home/presentation/screens/home_screen.dart` contains `bottom: const PreferredSize(` with `child: Divider()`
- `test/widget_test.dart` contains `expect(find.text('Dosly'), findsOneWidget)`
- Body `Center(child: Column(` with `Text('Hello World')` and `OutlinedButton` unchanged

## Done when

- [x] `HomeScreen.build()` returns a `Scaffold` with `appBar: AppBar(...)` containing title `Text('Dosly')`
- [x] AppBar has single action: `IconButton(onPressed: null, tooltip: 'Settings', icon: Icon(Icons.settings))`
- [x] AppBar has `bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Divider())`
- [x] Body content is unchanged — centered Column with "Hello World" text, SizedBox(height: 24), and "Theme preview" OutlinedButton
- [x] `context.push('/theme-preview')` call on the OutlinedButton is unchanged
- [x] `HomeScreen` class-level dartdoc describes the AppBar
- [x] First widget test asserts `find.text('Dosly')` finds one widget
- [x] `dart analyze` passes on all changed files
- [x] `flutter test` passes (all tests)
- [x] `flutter build apk --debug` succeeds

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-12, AC-13

## Completion Notes

**Completed**: 2026-04-12
**Files changed**: `lib/features/home/presentation/screens/home_screen.dart`, `test/widget_test.dart`
**Contract**: Expects 4/4 verified | Produces 5/5 verified
**Notes**: Clean execution, no deviations from plan. All 79 tests pass. APK build succeeds.
