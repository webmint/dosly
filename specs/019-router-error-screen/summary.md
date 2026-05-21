# Feature Summary: 019 — Router Error Screen

### What was built

When a user (or future deep link / notification action) navigates to a path the app doesn't recognise, dosly now shows a localized "Page not found" screen with a single "Go to home" recovery button instead of go_router's debug-only red default (which is blank in release builds). Closes bug 008 — escalated to Critical by audit 2026-04-30 because constitution §5.2 contractually plans notification-action deep links that would have hit the unhandled path.

### Changes

- **Task 001 — ARB keys + gen-l10n**: Added `errorScreenTitle`, `errorScreenBody`, `errorScreenGoHome` to `app_en.arb` / `app_de.arb` / `app_uk.arb` with English `@description` metadata; `flutter gen-l10n` regenerated all four `app_localizations*.dart` files.
- **Task 002 — Wire errorBuilder + private widget + integration test**: Added `errorBuilder: (context, state) => const _RouterErrorScreen()` to the `appRouter` provider and declared the private `_RouterErrorScreen` widget in the same library (Scaffold + AppBar with `automaticallyImplyLeading: false` + body Text + FilledButton calling `context.go('/')`). Appended Test 7 to `app_router_test.dart` (pushes `/nonexistent`, asserts no `AppBottomNav`, taps recovery button, verifies `HomeScreen` reappears).
- **Task 003 — Bug closure + architecture doc**: Marked `bugs/008-approuter-no-errorbuilder.md` Status: Fixed with a `## Resolution` section. Added one bullet to `docs/architecture.md` §"Routing" → "Conventions" describing the error-screen behavior.

### Files changed

- `lib/core/routing/` — 1 file modified (`app_router.dart`)
- `lib/l10n/` — 3 ARBs modified + 4 generated localization files regenerated
- `test/core/routing/` — 1 file modified (Test 7 appended)
- `bugs/` — 1 file closed
- `docs/` — 1 file (architecture.md) gained 1 bullet
- `specs/019-router-error-screen/` — spec, plan, 3 task files + README, review, verify, summary (artifacts)
- `.claude/` — memory + session-state updates

**Source code total**: 7 hand-edited files + 4 auto-regenerated = 11 files; ~50 net source LOC + 36 generated LOC.

### Key decisions

- **Widget location**: Private `class _RouterErrorScreen` declared inline in `app_router.dart` (not extracted to `lib/core/widgets/`) — 15-line widget with one consumer; extraction would be speculative reuse.
- **`automaticallyImplyLeading: false`**: Suppress the AppBar back arrow. Recovery is deterministic via the explicit `FilledButton`; an error path has no guaranteed previous frame to pop to (e.g., inbound deep link), so a back arrow would mislead.
- **Recovery via `context.go('/')`, not `Navigator.of(...)`**: Matches `docs/architecture.md` §"Routing" → "Conventions". Replaces the route stack and lands on the Today branch root.
- **Out of scope (deliberate)**: No platform-level `<intent-filter>` / `CFBundleURLTypes` wiring (separate future spec), no `redirect:` allow-list (paired with deep-link enablement), no `onException:` handler (no caller today), no widget extraction, no logging.

### Acceptance criteria

- [x] AC-1: `errorBuilder:` argument present in `GoRouter(...)` call
- [x] AC-2: Scaffold + AppBar(localized title) + body Text + FilledButton(localized, `context.go('/')`)
- [x] AC-3: Test 7 pushes `/nonexistent`, asserts title + button, taps, verifies HomeScreen recovery
- [x] AC-4: `app_en.arb` has 3 keys + `@description` blocks (`"Page not found"`, `"We couldn't find that destination."`, `"Go to home"`)
- [x] AC-5: `app_de.arb` has 3 keys (`"Seite nicht gefunden"`, `"Wir konnten dieses Ziel nicht finden."`, `"Zur Startseite"`)
- [x] AC-6: `app_uk.arb` has 3 keys (`"Сторінку не знайдено"`, `"Не вдалося знайти цей маршрут."`, `"На головну"`)
- [x] AC-7: `flutter gen-l10n` clean; all 4 generated files contain new getters
- [x] AC-8: Error screen has no `AppBottomNav` (renders outside `StatefulShellRoute`)
- [x] AC-9: Zero new `!` null-assertion sites in `app_router.dart`
- [x] AC-10: No new `lib/features/` imports in `app_router.dart`
- [x] AC-11: `dart analyze` exit 0
- [x] AC-12: `flutter test test/core/routing/app_router_test.dart` exit 0 (7/7)
- [x] AC-13: `flutter build apk --debug` exit 0
- [x] AC-14: `bugs/008-*.md` Status: Fixed + Resolution section
- [x] AC-15: `docs/architecture.md` § Routing → Conventions has the new bullet

**Verdict**: APPROVED (15/15 ACs PASS, Security PASS, Performance CLEAN, 1 Warning — Test 7 body-text assertion — left as a one-line follow-up).
