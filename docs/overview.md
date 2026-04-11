# dosly — Overview

**dosly** is a personal medication tracker for iOS and Android. It is a local-only Flutter app — no accounts, no cloud, no telemetry — built so one person can reliably record what they take, when they take it, and how well they are sticking to their schedule. The long-term goal is a full medication + schedule + intake + adherence workflow; the current codebase is the first step toward that, establishing the visual and architectural foundation.

**At a glance**

| | |
|---|---|
| Type | Mobile application (iOS + Android) |
| Framework | Flutter |
| Language | Dart |
| Architecture | Clean Architecture (see [`architecture.md`](architecture.md)) |
| State management | Riverpod (planned — not yet introduced) |
| Error handling | `Either<Failure, T>` via `fpdart` (planned — not yet introduced) |
| Persistence | `drift` on-device SQLite (planned — not yet introduced) |
| Network | None. Fully offline. |

## Current status

One feature has shipped: **[`001-m3-theme`](features/theme.md)** — Material 3 theme tokens, Roboto typography, `ThemeData` for light and dark, and a preview screen. No medication logic exists yet.

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

- [`architecture.md`](architecture.md) — layer boundaries, theme module, app-wide state pattern
- [`features/theme.md`](features/theme.md) — the Material 3 theme feature
- [`../constitution.md`](../constitution.md) — non-negotiable project rules
- [`../specs/`](../specs/) — per-feature specs, plans, and task breakdowns
