# Meds

## Overview

The **meds feature** owns the Meds tab — destination index 1 in `AppBottomNav`. The screen has a localized `AppBar`, a `FloatingActionButton` that opens a full-screen modal, and an intentionally empty body (medication list is pending a future spec). The add-medication modal is being built iteratively — feature 026 added the first form controls (name field + Save button); persistence, validation, and the rest of the form are still pending.

Everything in this feature lives under `lib/features/meds/presentation/`. There is no `domain/` or `data/` layer yet.

## MedsScreen

`MedsScreen` (in `lib/features/meds/presentation/screens/meds_screen.dart`) is a `StatelessWidget` that renders a `Scaffold` with:

- An `AppBar` whose title is the localized `bottomNavMeds` string (`context.l10n.bottomNavMeds`), shared with the bottom navigation bar destination label.
- A 1-px `Divider` pinned to the bottom of the `AppBar` via `PreferredSize`, matching the design template's header border rule.
- A `SizedBox.shrink()` body — intentionally empty until the medication-list feature is implemented.
- A `FloatingActionButton` (Material 3 FAB, `LucideIcons.plus`) with tooltip `context.l10n.medsAddFabTooltip` ("Add medication" in English). Tapping it calls `_openAddMedicationModal(context)`.

## Add-Medication Modal (iteration 1 — visual only)

`AddMedicationModal` (in `lib/features/meds/presentation/widgets/add_medication_modal.dart`) is a `StatefulWidget` that owns a `TextEditingController` for the medication-name field and disposes it in `dispose()`. It is a full-screen modal with:

- A `Scaffold + AppBar` carrying the localized title `context.l10n.medsAddTitle` ("Add medication").
- A leading `IconButton` (back arrow, `LucideIcons.arrowLeft`) that calls `Navigator.of(context).pop()`.
- A `SingleChildScrollView → Padding(16) → Column(crossAxisAlignment: stretch)` body containing:
  - An outlined `TextField` bound to `_nameController` with label `context.l10n.medsAddNameLabel`. The outlined, transparent styling (2px outline, `primary` on focus) comes from the global `inputDecorationTheme` in `lib/core/theme/app_theme.dart` — no call-site border/color overrides.
  - A full-width `FilledButton.icon` (`LucideIcons.save` + `context.l10n.medsAddSaveButton`) with `onPressed: () {}` — a **deliberate no-op**.

```dart
TextField(
  controller: _nameController,
  // Outline/label styling inherited from the global inputDecorationTheme.
  decoration: InputDecoration(
    labelText: context.l10n.medsAddNameLabel,
  ),
),
const SizedBox(height: 16),
FilledButton.icon(
  onPressed: () {},
  icon: const Icon(LucideIcons.save),
  label: Text(context.l10n.medsAddSaveButton),
),
```

The Save button's empty callback is **intentional and documented** (spec 026, iteration 1). It does not validate input, persist data, pop the modal, or give user feedback. Real save behaviour — drift persistence, domain layer, Riverpod provider — will be wired in the data-save iteration. There is still no `domain/` or `data/` layer for this feature.

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

| Key | English | German | Ukrainian | Added in |
|---|---|---|---|---|
| `medsAddFabTooltip` | Add medication | Medikament hinzufügen | Додати ліки | `011-meds-add-fab` |
| `medsAddTitle` | Add medication | Medikament hinzufügen | Додати ліки | `011-meds-add-fab` |
| `medsAddNameLabel` | Medication name | Medikamentenname | Назва ліків | `026-add-med-name-input` |
| `medsAddSaveButton` | Save | Speichern | Зберегти | `026-add-med-name-input` |

`medsAddFabTooltip` and `medsAddTitle` are intentionally distinct so they can diverge if UX copy evolves (e.g. a shorter tooltip). `medsAddNameLabel` and `medsAddSaveButton` are the first form-field keys; additional field keys will be added as the form grows.

## Routing

`MedsScreen` is mounted at `/meds` as branch index 1 of the `StatefulShellRoute.indexedStack` in `lib/core/routing/app_router.dart`. Navigate to it with:

```dart
context.go('/meds');
```

The modal is not a named route — it is pushed imperatively via `Navigator` (see above).

## Evolution

The add-medication form is being built iteratively:

- **Feature 026 (done)** — name `TextField` + Save button (visual only; Save is a no-op).
- **Pending** — real Save behaviour: `domain/` entities (`Medication`), repository interface, `data/` datasource (drift), concrete repository, Riverpod provider wired to the Save button.
- **Pending** — additional form fields (dose, schedule, etc.) as future specs are defined.
- **Pending** — medication list replacing the `SizedBox.shrink()` body of `MedsScreen`.

No changes to the `AppBar` structure, the `/meds` route path, or the modal-opening pattern are expected.

## Related

- [`../../specs/011-meds-add-fab/spec.md`](../../specs/011-meds-add-fab/spec.md) — the spec that introduced the FAB and modal scaffolding
- [`../../specs/026-add-med-name-input/spec.md`](../../specs/026-add-med-name-input/spec.md) — the spec that added the name field and Save button (iteration 1)
- [`home.md`](home.md) — `AppBottomNav` and `AppShell`, which host this screen
- [`../architecture.md`](../architecture.md) — `StatefulShellRoute` topology, routing conventions, and the `rootNavigator` context
- [`i18n.md`](i18n.md) — how ARB keys are added and translated
- [`icons.md`](icons.md) — icon conventions (Lucide vs. Material)
