# History

## Overview

The **history feature** owns the History tab — destination index 2 in `HomeBottomNav`. Currently the feature contains a single placeholder screen (`HistoryScreen`) with a localized `AppBar` and an empty body. Real adherence-history content will be added by a future spec.

Everything in this feature lives under `lib/features/history/presentation/`. There is no `domain/` or `data/` layer yet.

## HistoryScreen

`HistoryScreen` (in `lib/features/history/presentation/screens/history_screen.dart`) is a `StatelessWidget` that renders a `Scaffold` with:

- An `AppBar` whose title is the localized `bottomNavHistory` string (`context.l10n.bottomNavHistory`), shared with the bottom navigation bar destination label. No `actions`.
- A 1-px `Divider` pinned to the bottom of the `AppBar` via `PreferredSize`, matching the HTML design template's header border rule.
- A `SizedBox.shrink()` body — intentionally empty until the adherence-history feature is implemented.

```dart
// lib/features/history/presentation/screens/history_screen.dart
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.bottomNavHistory),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
```

The bottom navigation bar is not part of `HistoryScreen` — it is provided by the routing shell (`lib/core/routing/app_shell.dart`), which wraps all three tab screens inside a single `AppShell` `Scaffold`.

## Routing

`HistoryScreen` is mounted at `/history` as branch index 2 of the `StatefulShellRoute.indexedStack` declared in `lib/core/routing/app_router.dart`. Navigate to it with:

```dart
context.go('/history');
```

go_router's indexed stack preserves scroll position and back stack when the user switches away and returns.

## Localized title pattern

The AppBar title reuses the `bottomNavHistory` ARB key — the same string shown in the bottom nav destination label. This keeps the tab name and screen title in sync from a single translation. If the two ever need to diverge, introduce a dedicated `appBarHistory` key at that point.

## Evolution

The empty body is a deliberate placeholder. When the adherence-history feature lands, it will:

- Add `domain/` entities (e.g., `DoseRecord`) and a repository interface.
- Add `data/` datasources (local database via drift) and a concrete repository.
- Replace the `SizedBox.shrink()` body with a real history list or calendar widget powered by a Riverpod provider.

No changes to `AppBar` structure or the `/history` route path are expected.

## Related

- [`../../specs/007-meds-history-screens/spec.md`](../../specs/007-meds-history-screens/spec.md) — the spec that introduced this screen
- [`home.md`](home.md) — `HomeBottomNav` and `AppShell`, which host this screen
- [`../architecture.md`](../architecture.md) — `StatefulShellRoute` topology and routing conventions
- [`i18n.md`](i18n.md) — how `bottomNavHistory` is translated and how to add new strings
