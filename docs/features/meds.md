# Meds

## Overview

The **meds feature** owns the Meds tab — destination index 1 in `AppBottomNav`. The screen has a localized `AppBar`, a `FloatingActionButton` that opens a full-screen modal, and an intentionally empty body. Real medication-list content and the actual add-medication form are pending future specs.

Everything in this feature lives under `lib/features/meds/presentation/`. There is no `domain/` or `data/` layer yet.

## MedsScreen

`MedsScreen` (in `lib/features/meds/presentation/screens/meds_screen.dart`) is a `StatelessWidget` that renders a `Scaffold` with:

- An `AppBar` whose title is the localized `bottomNavMeds` string (`context.l10n.bottomNavMeds`), shared with the bottom navigation bar destination label.
- A 1-px `Divider` pinned to the bottom of the `AppBar` via `PreferredSize`, matching the design template's header border rule.
- A `SizedBox.shrink()` body — intentionally empty until the medication-list feature is implemented.
- A `FloatingActionButton` (Material 3 FAB, `Icons.add`) with tooltip `context.l10n.medsAddFabTooltip` ("Add medication" in English). Tapping it calls `_openAddMedicationModal(context)`.

## Add-Medication Modal (placeholder)

`AddMedicationModal` (in `lib/features/meds/presentation/widgets/add_medication_modal.dart`) is the scaffolding for the future add-medication form. It is a full-screen modal with:

- A `Scaffold + AppBar` carrying the localized title `context.l10n.medsAddTitle` ("Add medication").
- A leading `IconButton` (back arrow, `Icons.arrow_back`) that calls `Navigator.of(context).pop()`.
- A `SizedBox.shrink()` body — intentionally empty until the real form is specified.

The modal is **scaffolding only**. Its presence proves the routing pattern works end-to-end; the form fields will be added by the feature that implements medication creation.

### Opening the modal

`MedsScreen` uses a private helper to push the modal:

```dart
void _openAddMedicationModal(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const AddMedicationModal(),
    ),
  );
}
```

`rootNavigator: true` is required here because `MedsScreen` lives inside `AppShell`'s `StatefulShellRoute`. Without it, `Navigator.push` would use the branch navigator, and the modal would not cover the bottom nav bar. `fullscreenDialog: true` gives the route the platform-standard full-screen modal presentation (slide-up on iOS, fade on Android) without needing a named `go_router` route — appropriate for transient, non-deep-linkable UI.

This pattern (`rootNavigator: true` + `MaterialPageRoute(fullscreenDialog: true)`) is the **project-standard** way to present a full-screen modal over the AppShell. Future features that need a full-screen form should follow the same approach.

## Localization keys

Two ARB keys were added in feature `011-meds-add-fab`. They must be translated in all three supported locales when the feature ships:

| Key | English | German | Ukrainian |
|---|---|---|---|
| `medsAddFabTooltip` | Add medication | Medikament hinzufügen | Додати ліки |
| `medsAddTitle` | Add medication | Medikament hinzufügen | Додати ліки |

The keys are intentionally distinct (`medsAddFabTooltip` for the FAB tooltip, `medsAddTitle` for the modal AppBar title) so they can diverge if UX copy evolves (e.g. a shorter tooltip).

## Routing

`MedsScreen` is mounted at `/meds` as branch index 1 of the `StatefulShellRoute.indexedStack` in `lib/core/routing/app_router.dart`. Navigate to it with:

```dart
context.go('/meds');
```

The modal is not a named route — it is pushed imperatively via `Navigator` (see above).

## Evolution

The placeholder body and empty modal form will be replaced when the medication-management feature lands. Expected additions:

- `domain/` entities (e.g. `Medication`) and a repository interface.
- `data/` datasources (local database via drift) and a concrete repository.
- A real form inside `AddMedicationModal`, backed by a Riverpod provider.
- The `SizedBox.shrink()` body replaced with a medication list widget.

No changes to the `AppBar` structure, the `/meds` route path, or the modal-opening pattern are expected.

## Related

- [`../../specs/011-meds-add-fab/spec.md`](../../specs/011-meds-add-fab/spec.md) — the spec that introduced the FAB and modal scaffolding
- [`home.md`](home.md) — `AppBottomNav` and `AppShell`, which host this screen
- [`../architecture.md`](../architecture.md) — `StatefulShellRoute` topology, routing conventions, and the `rootNavigator` context
- [`i18n.md`](i18n.md) — how ARB keys are added and translated
- [`icons.md`](icons.md) — icon conventions (Lucide vs. Material)
