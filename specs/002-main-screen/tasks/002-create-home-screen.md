# Task 002: Create HomeScreen widget

**Status**: Complete
**Agent**: mobile-engineer
**Files**: `lib/features/home/presentation/screens/home_screen.dart` (new)
**Depends on**: 001
**Blocks**: 003, 004, 005
**Context docs**: None
**Review checkpoint**: No

## Completion Notes

**Completed**: 2026-04-11
**Files changed**: `lib/features/home/presentation/screens/home_screen.dart` (46 lines, new)
**Contract**: Expects 3/3 verified | Produces 6/6 verified
**Verification**: `dart analyze` clean per-file and project-wide
**Code review**: APPROVE, no findings
**Notes**: Directory chain `lib/features/home/presentation/screens/` created implicitly by the Write tool. The `Center` and `Column` are not `const` because they wrap the non-const `OutlinedButton` whose closure captures `context` — this is expected and correct. Dartdoc references `specs/002-main-screen/spec.md` twice (both §6 and §8 mentioned explicitly).

## Description

Create `HomeScreen` — the app's first placeholder main screen. A `StatelessWidget` that renders a centered "Hello World" text with an `OutlinedButton` below it that navigates to the theme preview via `context.push('/theme-preview')`. The button is temporary dev scaffolding scheduled for removal post-MVP; the screen file itself is permanent.

This is the first file under `lib/features/home/`, so the `home/presentation/screens/` directory chain must be created. `HomeScreen` imports **only** `package:flutter/material.dart` and `package:go_router/go_router.dart` — no cross-feature imports, no `core/` imports, no theme-preview imports. The screen does not know about `ThemePreviewScreen` directly; it only knows the route string `'/theme-preview'`.

## Change details

- Create directories as needed: `lib/features/home/`, `lib/features/home/presentation/`, `lib/features/home/presentation/screens/`.
- Create `lib/features/home/presentation/screens/home_screen.dart` with:
  - A library-level dartdoc comment (using `library;` directive) describing the file as the placeholder main screen with a temporary dev button.
  - Two imports exactly: `package:flutter/material.dart` and `package:go_router/go_router.dart`. No other imports.
  - A public `class HomeScreen extends StatelessWidget` with a `const HomeScreen({super.key});` constructor.
  - A class-level dartdoc (`///`) on `HomeScreen` that (a) describes it as the app's placeholder main screen and (b) explicitly flags the "Theme preview" button as temporary dev scaffolding scheduled for removal post-MVP, referencing `specs/002-main-screen/spec.md`. This satisfies constitution "Never leave bare TODOs" by providing spec context.
  - A `build` method returning this widget tree (every widget that can be `const` must be `const`):
    ```
    Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hello World'),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.push('/theme-preview'),
              child: const Text('Theme preview'),
            ),
          ],
        ),
      ),
    )
    ```
    (The `OutlinedButton` itself cannot be `const` because its `onPressed` closure captures `context`. The `Scaffold`, `Center`, `Column` cannot be `const` in this shape because they contain the non-const `OutlinedButton`. The `Text` and `SizedBox` children are `const`.)
  - A single TODO comment adjacent to the `OutlinedButton` block in the source: `// TODO(post-mvp): remove this dev entry point when theme_preview/ is deleted — see specs/002-main-screen/spec.md §6 and §8`. This satisfies constitution "Never leave bare TODOs" by referencing the spec.

## Done when

- [x] `lib/features/home/presentation/screens/home_screen.dart` exists
- [x] The file imports exactly `package:flutter/material.dart` and `package:go_router/go_router.dart`
- [x] The file defines a public `class HomeScreen extends StatelessWidget`
- [x] `HomeScreen.build` returns a `Scaffold` containing `Text('Hello World')` and `OutlinedButton` with `Text('Theme preview')`
- [x] The `OutlinedButton.onPressed` calls `context.push('/theme-preview')`
- [x] The `Scaffold` has no `appBar:`, `floatingActionButton:`, `bottomNavigationBar:`, or `drawer:`
- [x] `HomeScreen` dartdoc contains `specs/002-main-screen/spec.md`
- [x] TODO comment adjacent to `OutlinedButton` contains `specs/002-main-screen/spec.md`
- [x] All widgets that can be `const` are `const`
- [x] `dart analyze lib/features/home/presentation/screens/home_screen.dart` reports zero diagnostics
- [x] No `print()`, `debugPrint()`, `!`, or `dynamic` usage
- [x] `dart analyze` reports zero diagnostics project-wide

## Contracts

### Expects

- `pubspec.yaml` lists `go_router` under `dependencies:` (produced by task 001).
- `package:go_router/go_router.dart` is importable (produced by task 001).
- `lib/features/home/presentation/screens/` directory does not yet exist (or is empty of Dart files).

### Produces

- `lib/features/home/presentation/screens/home_screen.dart` exists with the literal declaration `class HomeScreen extends StatelessWidget`.
- The file's `build` method source contains the literal strings `'Hello World'`, `'Theme preview'`, and `context.push('/theme-preview')`.
- The file's import block contains exactly the two lines `import 'package:flutter/material.dart';` and `import 'package:go_router/go_router.dart';`.
- A dartdoc comment block above `class HomeScreen` contains the literal substring `specs/002-main-screen/spec.md`.
- A `// TODO(post-mvp):` comment adjacent to the `OutlinedButton` declaration contains the literal substring `specs/002-main-screen/spec.md`.
- `dart analyze lib/features/home/presentation/screens/home_screen.dart` exits 0 with no diagnostics.

## Spec criteria addressed

- AC-4 (HomeScreen widget shape: Scaffold/Center/Column/Text/SizedBox/OutlinedButton with `context.push`)
- AC-5 (imports only material + go_router)
- AC-6 (no AppBar/FAB/BottomNav/Drawer)
- AC-7 (exact strings `'Hello World'` and `'Theme preview'`) — HomeScreen side; task 005 verifies via widget assertions
- AC-8 (HomeScreen dartdoc references spec)
- AC-13 (dart analyze clean — per-file verification here; project-wide verification after task 005)
- AC-16 (no `print`/`debugPrint`/`!`/`dynamic` — writer discipline)
- AC-17 (const where possible — linter-enforced via `prefer_const_constructors`)

## Notes

- **Feature-layer coupling to go_router**: `HomeScreen` imports `package:go_router/go_router.dart` solely for the `context.push` extension method on `BuildContext`. This is the one place `go_router` leaks into a feature layer in this spec. The alternative (wrapping in a helper function in `app_router.dart`) was rejected in spec Open Q §8 #5 as ceremony for a call site scheduled for deletion.
- **`const` discipline**: the `OutlinedButton`'s `onPressed` closure captures `context`, so the button and its enclosing widgets cannot be `const`. This is expected and AC-17 allows it. Lower in the tree, `const Text(...)` and `const SizedBox(...)` must still be `const`.
- **Directory creation**: the agent must create the parent directories as well — `lib/features/home/presentation/screens/`. No `.gitkeep` files or placeholder content in the parent directories.
- **No `home/domain/` or `home/data/`**: this task creates presentation only. Creating empty `domain/` or `data/` directories is out of scope per spec §6.
- **No tests for `HomeScreen` in isolation**: task 005 rewrites `widget_test.dart` to exercise `HomeScreen` via `DoslyApp`. A standalone test file for `HomeScreen` is out of scope per spec §6.
