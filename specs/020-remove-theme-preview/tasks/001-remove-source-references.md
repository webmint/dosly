# Task 001: Remove all source references to theme_preview

**Status**: Complete
**Agent**: mobile-engineer
**Files**: `lib/core/routing/app_router.dart`, `lib/features/home/presentation/screens/home_screen.dart`, `lib/app.dart`
**Depends on**: None
**Blocks**: 003
**Context docs**: None
**Review checkpoint**: No

**Description**:
Strip every inbound reference to the `theme_preview` feature from the production
source tree, leaving the feature folder itself in place (it is deleted later in
Task 003, after the tests are also cleaned). After this task the `theme_preview`
files are orphaned — nothing imports or routes to them — but `dart analyze` still
passes because an unreferenced library is not an error.

**Change details**:
- In `lib/core/routing/app_router.dart`:
  - Remove the import at line 22: `import '../../features/theme_preview/presentation/screens/theme_preview_screen.dart';`
  - Remove the `/theme-preview` `GoRoute` block (lines 74–79) **including** its
    `// TODO(post-mvp): remove this route ...` comment. The remaining top-level
    routes are the `StatefulShellRoute`, the `/settings` `GoRoute`, and the
    `errorBuilder`.
  - Update the library dartdoc (lines 6–8): remove the clause describing "a
    sibling top-level `GoRoute` for `/theme-preview` that renders WITHOUT the
    shell". Keep the rest of the dartdoc (shell branches, branch-order note).
- In `lib/features/home/presentation/screens/home_screen.dart`:
  - Remove the dev button block in the body `Column` (lines 56–64): the
    `const SizedBox(height: 24)`, the `// TODO(post-mvp): remove this dev entry
    point ...` comment, and the `OutlinedButton(onPressed: () => context.push('/theme-preview'), ...)`.
  - Simplify the body: the `Column` now has a single child, so replace
    `body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Hello World')]))`
    with `body: const Center(child: Text('Hello World'))`.
  - Trim the class dartdoc (lines 20–27): remove the paragraph about the
    "Theme preview" `OutlinedButton` and the `/theme-preview` removal plan. Keep
    the description of the AppBar, settings gear, and the bottom-nav-via-shell note.
  - **Keep** `import 'package:go_router/go_router.dart';` (line 9) — still used by
    `context.push('/settings')` at line 42.
- In `lib/app.dart`:
  - Update the library dartdoc (lines 10–13): replace the sentence "Routing is
    delegated to [appRouterProvider] which currently exposes `/` ([HomeScreen])
    and a temporary dev-only `/theme-preview` route — the preview route will be
    removed in the final development stages (see specs/002-main-screen/spec.md)."
    with a version that drops the `/theme-preview` mention, e.g. "Routing is
    delegated to [appRouterProvider] which exposes `/` ([HomeScreen]), `/meds`,
    `/history`, and `/settings`."
  - Do NOT change any code, import, or the `MaterialApp.router` arguments in
    `app.dart` — dartdoc text only.

## Contracts

### Expects
- `lib/core/routing/app_router.dart` currently imports `theme_preview_screen.dart`
  and declares a `GoRoute(path: '/theme-preview', ...)`.
- `lib/features/home/presentation/screens/home_screen.dart` currently contains an
  `OutlinedButton` with `child: const Text('Theme preview')` and
  `context.push('/theme-preview')`, plus `context.push('/settings')`.
- `lib/app.dart` library dartdoc currently contains the string `/theme-preview`.

### Produces
- `lib/core/routing/app_router.dart` contains neither the substring `theme_preview`
  nor `ThemePreviewScreen` nor `/theme-preview`.
- `lib/features/home/presentation/screens/home_screen.dart` contains neither
  `'Theme preview'` nor `/theme-preview`, still contains
  `import 'package:go_router/go_router.dart';`, and still contains
  `context.push('/settings')`.
- `lib/app.dart` contains no `/theme-preview` substring; its `MaterialApp.router`
  call and imports are unchanged (still imports `core/routing/app_router.dart`).

**Done when**:
- [x] `app_router.dart` has no `theme_preview` import, no `/theme-preview` route, no related TODO; dartdoc updated.
- [x] `home_screen.dart` body renders only the centered `Text('Hello World')`; the "Theme preview" button, spacer, and TODO are gone; `go_router` import retained; class dartdoc trimmed.
- [x] `app.dart` library dartdoc no longer mentions `/theme-preview`; no code change.
- [x] `dart analyze` passes on all three changed files (the orphaned `theme_preview` folder produces no diagnostics).

**Spec criteria addressed**: AC-3, AC-4, AC-5

## Completion Notes

**Completed**: 2026-05-22
**Files changed**: lib/core/routing/app_router.dart, lib/features/home/presentation/screens/home_screen.dart, lib/app.dart
**Contract**: Expects [3/3 verified] | Produces [3/3 verified]
**Notes**: `dart analyze` → "No issues found!". `go_router` import + `context.push('/settings')` retained in home_screen.dart. Code review APPROVE WITH WARNINGS — one Info-level note that app.dart's dartdoc now lists the concrete route set (`/`, `/meds`, `/history`, `/settings`), which could drift if routes change later; left as-is since the list is accurate today and matches the prior dartdoc style. Body simplified to `const Center(child: Text('Hello World'))`.
