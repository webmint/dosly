# dosly — Overview

**dosly** is a personal medication tracker for iOS and Android. It is a local-only Flutter app — no accounts, no cloud, no telemetry — built so one person can reliably record what they take, when they take it, and how well they are sticking to their schedule. The long-term goal is a full medication + schedule + intake + adherence workflow; the current codebase is the first step toward that, establishing the visual and architectural foundation.

**At a glance**

| | |
|---|---|
| Type | Mobile application (iOS + Android) |
| Framework | Flutter |
| Language | Dart |
| Architecture | Clean Architecture (see [`architecture.md`](architecture.md)) |
| State management | Riverpod (`flutter_riverpod`) |
| Error handling | `Either<Failure, T>` via `fpdart` |
| Persistence | `shared_preferences` (settings); `drift` SQLite (planned for medication data) |
| Icon set | Lucide via [`lucide_icons_flutter`](features/icons.md) (matches the HTML design template) |
| Network | None. Fully offline. |

## Current status

Features shipped so far:

- **[`001-m3-theme`](features/theme.md)** — Material 3 theme tokens, Roboto typography, `ThemeData` for light and dark, and a preview screen.
- **`002-main-screen`** — A placeholder `HomeScreen` and the adoption of `go_router` as the project's routing foundation. The `ThemePreviewScreen` is now reached via a dev button on `HomeScreen` and is scheduled for removal post-MVP. See [`architecture.md` § Routing](architecture.md#routing).
- **[`004-lucide-icons`](features/icons.md)** — Adopted Lucide (via `lucide_icons_flutter`) as the app-wide icon set, replacing Material `Icons.*`.
- **[`005-bottom-nav`](features/home.md)** — Material 3 bottom navigation bar with three destinations (Today · Meds · History).
- **[`009-theme-settings`](features/settings.md)** — Settings screen with a "Use system theme" toggle and a Light/Dark segmented button. Introduced Riverpod, `shared_preferences`, and the `Either<Failure, T>` error-handling pattern.

No medication logic exists yet.

## Getting started

The project is driven by slash commands documented in [`CLAUDE.md`](../CLAUDE.md) at the repository root. The typical flow is:

1. `/specify` — write a feature specification
2. `/plan` — produce a technical plan from the spec
3. `/breakdown` — split the plan into tasks
4. `/execute-task` — implement one task
5. `/verify` → `/review` → `/finalize` — validate and document

Running the app locally:

```bash
flutter pub get
flutter run -d ios      # iOS simulator
flutter run -d android  # Android emulator
```

## Further reading

- [`architecture.md`](architecture.md) — layer boundaries, Riverpod bootstrap, SharedPreferences, Failure hierarchy
- [`features/theme.md`](features/theme.md) — the Material 3 theme feature
- [`features/home.md`](features/home.md) — the home screen and its bottom navigation bar
- [`features/icons.md`](features/icons.md) — the Lucide icon set
- [`features/settings.md`](features/settings.md) — Settings screen and theme-mode persistence
- [`../constitution.md`](../constitution.md) — non-negotiable project rules
- [`../specs/`](../specs/) — per-feature specs, plans, and task breakdowns
