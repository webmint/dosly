## Feature Summary: 036 — Tap-to-Edit Medication

### What was built
Users can now edit an existing medication by tapping its tile in the list. The tap reopens the **same** add-medication modal, pre-filled with that medication's current values; saving persists the changes in place — preserving the medication's `id`, `createdAt`, and the IDs of unchanged time slots — and the list updates reactively. This adds the first medication **update** path through all three layers (domain use case, repository, drift data source).

### Changes
- **Task 001** — Datasource upsert: added transactional `upsertMedication` using `insertOnConflictUpdate` (cascade-safe, not REPLACE), removed-slot delete scoped by `medicationId & id.isNotIn(...)`, plus an empty-slots `ArgumentError` guard.
- **Task 002** — Repository update: added `update(Medication)` to the contract + impl (`try/catch → Left(Failure.unknown)`); patched 5 hand-written `implements MedicationRepository` test fakes atomically.
- **Task 003** — Edit use case + provider: new pure-Dart `EditMedication` (same validation as `AddMedication`, preserves `id`/`createdAt`, reconciles slot IDs) wired via `editMedicationProvider`.
- **Task 004** — Unit tests for `EditMedication` (happy path, id/createdAt preservation, slot keep/add/remove, 4 validation branches, repo-failure passthrough).
- **Task 005** — Round-trip repository `update` tests against real in-memory drift (in-place update, preserved/removed slot IDs, sibling untouched, failure path).
- **Task 006** — Localization keys `medsEditTitle` / `medsEditSaveSuccess` in en/de/uk.
- **Task 007** — Parameterized the modal with `Medication? initial`: `initState` pre-fill, edit-mode title/success, save routing to `editMedicationProvider`, and picker `initialFormKey` seeding.
- **Task 008** — Tile tap wiring: `InkWell` + `onTap` on the tile, `onTapItem` through the section, `_openEditMedicationModal` on the screen.
- **Task 009** — Widget tests for edit-mode pre-fill, add-vs-edit save routing, and tile tap.
- **Task 010** — Documented the update/edit path in `medication-persistence.md` and `meds.md`.

### Files changed
- `lib/features/meds/` — 10 files (domain contract + `edit_medication.dart` [new]; data source + repo impl; providers + regen `.g.dart`; modal, tile, section, screen)
- `lib/l10n/` — 7 files (3 ARB + 4 regenerated `app_localizations*.dart`)
- `test/features/meds/` — 5 files (2 new: `edit_medication_test.dart`, `medication_tile_test.dart`; 3 extended)
- `docs/features/` — 2 files updated
- `specs/036-meds-edit/` — 15 files (spec, plan, contracts, review, tasks)

_Total: 41 files changed, 2846 insertions(+), 119 deletions(−). Verified: `dart analyze` clean, `flutter test` 568/568, `flutter build apk` ✅._

### Key decisions
- **Reuse strategy**: parameterize `AddMedicationModal` with `Medication? initial` (const ctor kept) rather than extract a shared form — smallest surface; add path stays byte-identical when `initial == null`.
- **Update persistence**: `insertOnConflictUpdate` for the medication row (UPDATE in place); a REPLACE would cascade-delete every time slot via the `onDelete: cascade` FK on each edit.
- **Slot-ID preservation**: reconcile in the use case — reuse the original slot verbatim where `minuteOfDay` matches, mint a new ID otherwise; the data source only persists what it's given.
- **No `getById`**: the modal passes the in-hand `Medication` into `EditMedication`, avoiding a new read method and DB round-trip.

### Deviations from plan
- **Task 002**: 5 test fakes patched, not 4 — `add_medication_modal_test.dart`'s `_RecordingMedicationRepository` also needed the `update` stub (added a `capturedUpdate` field for Task 009).
- **Task 003**: slot reconciliation keys `minuteOfDay → TimeSlot` (whole slot passed through verbatim), not `minuteOfDay → TimeSlotId` — preserves each unchanged slot's `doseOverride`, closing a latent data-loss path (review fix).
- **Task 007**: edit now forwards `notes: original.notes` and preserves an already-Continuous medication's `startDate` instead of restamping today — fields the form doesn't collect were being silently wiped by `copyWith` (review fix).
- **Task 008**: the pre-existing "tile not tappable" screen test (spec-034 deferred-navigation behavior) was rewritten to "tile tappable → modal opens", since this feature removes that deferral.

### Acceptance criteria
- [x] AC-1: Tapping a tile opens the modal (root nav, fullscreen dialog) with `initial` set
- [x] AC-2: Tile exposes `onTap` + `InkWell` (≥48 dp); unchanged when no `onTap`
- [x] AC-3: Edit title `medsEditTitle`; add title `medsAddTitle`; Save label unchanged
- [x] AC-4: Name, form picker, and form-dependent fields pre-filled
- [x] AC-5: Intake chips (ascending), intake type, and course fields pre-filled
- [x] AC-6: `_MedicationFormPicker.initialFormKey` seeds the display; null = unchanged
- [x] AC-7: `MedicationRepository.update` declared + implemented; no exception escapes
- [x] AC-8: `upsertMedication` updates the row in place (one row per `id`)
- [x] AC-9: Slot reconciliation preserves/adds/removes IDs; no orphans, siblings untouched
- [x] AC-10: `EditMedication` preserves original `id` and `createdAt`
- [x] AC-11: Same validation as add; repository not called on invalid input
- [x] AC-12: Edit routes `editMedicationProvider`; success pops, validation-failure stays; Save disabled in flight
- [x] AC-13: List updates reactively after a successful edit
- [x] AC-14: Add mode behaviorally unchanged; add tests pass unmodified
- [x] AC-15: New keys in en/de/uk with `@`-descriptions in en; gen-l10n clean
- [x] AC-16: `dart analyze` clean and `flutter test` passes with the full new test set
