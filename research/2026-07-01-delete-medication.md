# Research: Delete Medication (Finish CRUD)

**Date**: 2026-07-01
**Topic**: "feature delete medication to finish crud"
**Verdict**: **Feasible** — the lowest-complexity of the four CRUD operations. The persistence groundwork (cascade FK, reactive list, composition seam) is already in place; delete is a small, well-patterned addition. The only real decisions are UX (where the affordance lives + confirmation model).

## Summary

Delete is the last missing letter of CRUD: **Create** (`AddMedication`), **Read** (`watchAll` → live list), and **Update** (`EditMedication` + `update`/upsert) all shipped, most recently in spec 036 (tap-to-edit). There is **no delete anywhere** — `MedicationRepository` exposes `add` / `update` / `watchAll` only, and no data-source or UI path removes a row. The good news: this is the *easiest* CRUD op to add because the schema already does the hard part — `TimeSlots.medicationId` has `onDelete: cascade` (enforced via `pragma foreign_keys = ON` per connection), so deleting a medication row **automatically removes all its time slots** in one statement, with no manual child reconciliation (the messy part of the edit path). The reactive drift join in `watchAllMedications` already fires on delete, so the list refreshes for free. No new dependencies. The work is a mechanical repeat of the add/edit vertical slice, plus one genuinely new UI pattern for this codebase: a confirmation dialog.

## Codebase Findings

### Existing Related Code
| Area | File | Relevance |
|------|------|-----------|
| Persistence contract | `domain/repositories/medication_repository.dart` | Has `add` / `update` / `watchAll`. **No `delete`, no `getById`.** Add `delete(MedicationId)`. |
| Data source | `data/datasources/medication_local_data_source.dart` | `insert` + `upsert` (with manual slot reconciliation). No delete. A delete is a **one-liner** — cascade handles slots. |
| Repo impl | `data/repositories/medication_repository_impl.dart` | Each method try/catches → `Left(Failure.unknown)`. New `delete` mirrors this exactly. |
| Composition seam | `presentation/providers/medication_providers.dart` | The one presentation file allowed to import `data/`. `deleteMedicationProvider` slots next to `addMedicationProvider`/`editMedicationProvider`. |
| Edit surface (tap site) | `presentation/screens/meds_screen.dart:408` + `add_medication_modal.dart` | Tapping a tile opens the modal in edit mode (`initial != null`). Natural home for a trash icon in the AppBar. |
| List tile | `presentation/widgets/medication_tile.dart` | Dumb widget; `item.medication.id` available. Candidate for swipe-to-delete if you prefer list-level delete. |
| Cascade FK | `core/database/database.dart:31` | `onDelete: cascade` + FK pragma ON → **delete med ⇒ slots auto-deleted.** |
| Entity id | `domain/value_objects/medication_id.dart` | `MedicationId(String value)` — all a delete needs. |

### Patterns Available
- **Cascade delete** → the delete is `(delete(medications)..where((m) => m.id.equals(id))).go()`. No transaction gymnastics, no `NOT IN ()` footgun (the edit path's hazard).
- **Reactive auto-refresh** → the watched join re-emits on delete; the list updates with zero extra wiring.
- **Vertical-slice template** → add/edit already model contract → data source → impl → use case → provider. Delete is a thinner copy.
- **SnackBar idiom** → success/error SnackBars already used in the modal and settings (`ScaffoldMessenger.showSnackBar`).

### Gaps (must be built)
- `MedicationRepository.delete(MedicationId)` + impl + `MedicationLocalDataSource.deleteMedication(String id)`.
- A `DeleteMedication` use case (constitution forbids screens calling repos directly).
- `deleteMedicationProvider`.
- **New UI pattern for this codebase**: a confirmation dialog — `showDialog`/`AlertDialog`/`Dismissible` are used **nowhere** in `lib/` today. `SnackBarAction` (for undo) is also unused.
- l10n strings: delete label, confirm-dialog title/body, confirm/cancel, success SnackBar.

## Constitution Constraints
| Rule | Impact |
|------|--------|
| §4.1.1 "Screens never call repositories directly" | Delete **must** go through a `DeleteMedication` use case, not a raw repo call. |
| §3.2 `Either<Failure, T>` everywhere | New repo method + use case return `Future<Either<Failure, T>>`; the caller `.fold`s both branches. |
| §2.1 layer boundaries | Use case is pure-Dart domain; only `medication_providers.dart` touches `data/`. |
| §3.4 Testing (mandatory) | Use-case unit test (success + repo-failure) + in-memory drift delete test (**assert slots cascade-deleted**) + widget test (confirm → delete → gone). |
| §4.3.1 tap targets ≥48dp | Trash `IconButton` / swipe target sized accordingly. |
| Privacy / no backend | Delete is **irreversible** — no recycle bin, no sync. Argues for a confirmation gate. |

## Approaches

Two orthogonal decisions: **(1) where the affordance lives** and **(2) the safety model**.

### Where — Option A: Trash icon in the edit-modal AppBar *(recommended)*
- Tapping a tile already opens the edit modal; add a delete `IconButton` to its AppBar (edit mode only, i.e. `initial != null`). "Finish CRUD" in the exact surface where update already lives.
- **Pros**: Smallest, most discoverable; reuses the existing tap→edit route; edit modal already holds the full `Medication`. Minimal changes.
- **Cons**: Requires opening the modal to delete (one extra tap vs. a swipe).
- **Complexity**: Low.

### Where — Option B: Swipe-to-dismiss on the list tile
- Wrap `MedicationTile` in a `Dismissible` with a red delete background.
- **Pros**: Fast, familiar mobile gesture; delete without opening anything.
- **Cons**: New pattern; must reconcile `Dismissible` with the existing tap-to-edit `InkWell` and the animated list; accidental-swipe risk raises the bar for confirmation/undo.
- **Complexity**: Medium.

### Safety — Option 1: Confirmation dialog *(recommended)*
- `AlertDialog` ("Delete *name*? This can't be undone" → Cancel / Delete). Delete only on confirm.
- **Pros**: Prevents irreversible accidental loss of sensitive data; standard for destructive actions. Simple.
- **Cons**: One extra tap.

### Safety — Option 2: Delete immediately + Undo SnackBar
- Delete right away, show `SnackBar` with `SnackBarAction('Undo')` that re-inserts.
- **Pros**: Frictionless.
- **Cons**: Undo needs a **re-insert path** that preserves the original `id`/`createdAt` (repo `add(medication)` can do this, but bypasses the "go through a use case" rule unless wrapped); more moving parts. Overkill for a low-frequency action.

**Recommended combination: A + 1** — a trash icon in the edit-modal AppBar guarded by a confirmation dialog. It's the literal "finish CRUD" in the surface update already occupies, it's the smallest change, and the confirmation matches the irreversible/PHI nature of the data. (Swipe-to-delete, Option B, is a reasonable *additional* affordance for a later polish spec.)

## Complexity Assessment
| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | **Low** | ~6–7 files: repo contract, data source, repo impl, use case (new), provider, modal (delete button + dialog), l10n. Cascade removes the slot-handling that made edit medium-complexity. |
| New dependencies | **None** | drift delete, `showDialog`/`AlertDialog` are stock Flutter. |
| Risk | **Low–Medium** | Destructive + irreversible → confirmation is the mitigation. Minor decision: deleting a non-existent id → treat as idempotent success, or `NotFoundFailure`. Verify a swipe (if chosen) doesn't fight the tap-to-edit `InkWell`. |

*(External research skipped — no signals: no new libraries, integrations, or patterns beyond what the codebase and stock Flutter already provide.)*

## Recommendation

**Proceed.** Run:

```
    /specify "Delete a medication: add a trash IconButton to the edit-medication modal's AppBar (edit mode only) that opens a confirmation AlertDialog; on confirm, invoke a new DeleteMedication use case → MedicationRepository.delete(MedicationId) → MedicationLocalDataSource.deleteMedication (single drift delete; TimeSlots cascade-delete via the FK); pop the modal and show a success SnackBar. Add deleteMedicationProvider in the composition seam and l10n strings for the button, dialog, and confirmation."
```

`/specify` should pin three small decisions: (1) affordance placement — edit-modal trash icon (recommended) vs. swipe-to-delete; (2) confirmation dialog vs. undo-SnackBar; (3) deleting an already-absent id → idempotent success vs. `NotFoundFailure`.
