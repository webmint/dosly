# Meds

## Overview

The **meds feature** owns the Meds tab — destination index 1 in `AppBottomNav`. Currently the feature contains a single placeholder screen (`MedsScreen`) with a localized `AppBar` and an empty body. Real medication-list content will be added by a future spec.

Everything in this feature lives under `lib/features/meds/presentation/`. There is no `domain/` or `data/` layer yet.

## MedsScreen

`MedsScreen` (in `lib/features/meds/presentation/screens/meds_screen.dart`) is a `StatelessWidget` that renders a `Scaffold` with:

- An `AppBar` whose title is the localized `bottomNavMeds` string (`context.l10n.bottomNavMeds`), shared with the bottom navigation bar destination label. No `actions`.
- A 1-px `Divider` pinned to the bottom of the `AppBar` via `PreferredSize`, matching the HTML design template's header border rule.
- A `SizedBox.shrink()` body — intentionally empty until the medication-list feature is implemented.

```dart
// lib/features/meds/presentation/screens/meds_screen.dart
class MedsScreen extends StatelessWidget {
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.bottomNavMeds),
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

The bottom navigation bar is not part of `MedsScreen` — it is provided by the routing shell (`lib/core/routing/app_shell.dart`), which wraps all three tab screens inside a single `AppShell` `Scaffold`.

## Routing

`MedsScreen` is mounted at `/meds` as branch index 1 of the `StatefulShellRoute.indexedStack` declared in `lib/core/routing/app_router.dart`. Navigate to it with:

```dart
context.go('/meds');
```

go_router's indexed stack preserves scroll position and back stack when the user switches away and returns.

## Localized title pattern

The AppBar title reuses the `bottomNavMeds` ARB key — the same string shown in the bottom nav destination label. This keeps the tab name and screen title in sync from a single translation. If the two ever need to diverge, introduce a dedicated `appBarMeds` key at that point.

## Evolution

The empty body is a deliberate placeholder. When the medication-list feature lands, it will:

- Add `domain/` entities (e.g., `Medication`) and a repository interface.
- Add `data/` datasources (local database via drift) and a concrete repository.
- Replace the `SizedBox.shrink()` body with a real list widget powered by a Riverpod provider.

No changes to `AppBar` structure or the `/meds` route path are expected.

## Related

- [`../../specs/007-meds-history-screens/spec.md`](../../specs/007-meds-history-screens/spec.md) — the spec that introduced this screen
- [`home.md`](home.md) — `AppBottomNav` and `AppShell`, which host this screen
- [`../architecture.md`](../architecture.md) — `StatefulShellRoute` topology and routing conventions
- [`i18n.md`](i18n.md) — how `bottomNavMeds` is translated and how to add new strings
