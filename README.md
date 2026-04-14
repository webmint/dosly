# dosly

> Developed with assistance of [AIDevTeamForge](https://github.com/webmint/AIDevTeamForge).

Personal medication tracker for iOS and Android. Local-only — no accounts, no cloud, no telemetry.

Built with Flutter. The long-term goal is a full medication + schedule + intake + adherence workflow; the current codebase establishes the visual and architectural foundation.

## Tech stack

| | |
|---|---|
| Framework | Flutter (Dart SDK ^3.11.1) |
| Architecture | Clean Architecture (`lib/core/` + `lib/features/`) |
| Routing | [`go_router`](https://pub.dev/packages/go_router) |
| Icons | [`lucide_icons_flutter`](https://pub.dev/packages/lucide_icons_flutter) |
| Typography | Roboto (bundled) + Material 3 theme |
| State management | Riverpod *(planned)* |
| Error handling | `Either<Failure, T>` via `fpdart` *(planned)* |
| Persistence | `drift` on-device SQLite *(planned)* |
| Network | None — fully offline |

## Getting started

```bash
flutter pub get
flutter run -d ios       # iOS simulator
flutter run -d android   # Android emulator
```

Other common commands:

```bash
flutter test             # unit + widget tests
dart analyze             # lint + type check
dart format lib test     # format
flutter build apk        # debug Android build
```

## Project layout

```
lib/
  core/          # theme, routing, errors, utilities
  features/     # one folder per feature (data / domain / presentation)
test/           # mirrors lib/
docs/           # architecture and feature documentation
specs/          # per-feature specs, plans, and task breakdowns
```

## Documentation

- [`docs/overview.md`](docs/overview.md) — project overview and current status
- [`docs/architecture.md`](docs/architecture.md) — layer boundaries and patterns
- [`constitution.md`](constitution.md) — non-negotiable project rules
- [`CLAUDE.md`](CLAUDE.md) — workflow commands used to drive development
