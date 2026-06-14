# Plan: Add-Medication Form Picker (visual-only, iteration 2)

**Date**: 2026-06-13
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Insert a self-contained, presentation-only medication-form picker into `AddMedicationModal`, between the existing name field and the no-op Save button. The picker is a **private `StatefulWidget`** within the modal's library that owns its own selection + open/closed state via `setState`; it renders a tappable display row (using `InputDecorator` for the outlined-with-floating-label look, consistent with the name field) that expands an `AnimatedSize` grid of 8 form chips built by iterating a presentation-only list. No domain/data, no Riverpod, no persistence; the selection is intentionally unconsumed this iteration.

## Technical Context

**Architecture**: Clean Architecture — **presentation layer only**. No `domain/` or `data/` touched (per spec §6).
**Error Handling**: N/A — no fallible operations (no I/O, no parsing, no async). Pure local UI state.
**State Management**: **Local `setState`** inside a private `StatefulWidget`. No Riverpod / `ConsumerStatefulWidget` (spec §3.5, AC-7). Selection state is encapsulated in the picker and not surfaced to the parent (no callback this iteration — added when the data-save iteration needs it; avoids speculative generality per constitution KISS/YAGNI).

## Constitution Compliance

| Rule | Status | Note |
|------|--------|------|
| §2.1 layer boundaries (presentation only) | ✅ Compliant | No `domain/`/`data/` code; the 8-form list is a presentation-only structure inside the widget file. |
| No Flutter imports in `domain/` | ✅ N/A | No domain code. |
| §4.2.1 no `!` null assertion | ✅ Compliant | Strings via `context.l10n` (single sanctioned `!` site is `l10n_extensions.dart`); selection is a non-null `int` index. |
| Dartdoc on new public APIs | ✅ Compliant | Library + `AddMedicationModal` dartdoc updated; the private picker gets `///` too (good practice). |
| Dispose hygiene | ✅ Compliant | Use **implicit** animations (`AnimatedSize`, `AnimatedRotation`) — no `AnimationController`, nothing to dispose. The existing `_nameController` disposal is unchanged. |
| Theme-driven, no call-site color literals (MEMORY F005) | ✅ Compliant | All colors from `colorScheme` roles (all present in `app_color_schemes.dart`, both brightnesses). |
| SOLID / DRY / KISS | ✅ Compliant | 8 chips rendered by iterating one list, not duplicated 8×. |
| `dart analyze` zero issues, no lint suppression (MEMORY F010) | ✅ Target | Enforced by PostToolUse hook + AC-12. |
| Icons via `lucide_icons_flutter`, no new dep | ✅ Compliant | Material `Icons.*` fallback only where a Lucide name doesn't compile (spec §7). |
| l10n: keys in 3 ARBs, `@`-meta en-only, `flutter gen-l10n` (MEMORY F006) | ✅ Compliant | 19 keys; bindings regenerated, never hand-edited. |

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Domain | — (none) | — |
| Data | — (none) | — |
| Presentation | Private `_MedicationFormPicker` `StatefulWidget` + private `_MedFormOption` value type + `final` 8-item list, inserted into the modal body | `lib/features/meds/presentation/widgets/add_medication_modal.dart` (Modify) |
| Presentation — l10n | 19 new keys (3 chrome + 8 names + 8 subs) across 3 locales + regenerated bindings | `lib/l10n/app_{en,de,uk}.arb` (Modify) + `app_localizations*.dart` (Regenerate) |
| Test | Picker widget tests appended; spec-026 tests preserved | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` (Modify) |

### Presentation-only data shape

A private, immutable value type + a top-level `final` list (not `const` — the l10n resolvers are closures), iterated to build both the grid chips and the selected display-row content:

```dart
@immutable
class _MedFormOption {
  const _MedFormOption({
    required this.key,        // stable id, matches the PLANNED domain enum name
    required this.icon,       // Lucide IconData (Material fallback if a name fails)
    required this.name,       // localized display name
    required this.sub,        // localized sub-description
  });
  final String key;
  final IconData icon;
  final String Function(AppLocalizations l10n) name;
  final String Function(AppLocalizations l10n) sub;
}

// Order = HTML grid order (spec §3.6). No domain enum — presentation only.
final List<_MedFormOption> _medFormOptions = [
  _MedFormOption(key: 'tablet',    icon: LucideIcons.pills,    name: (l) => l.medsAddFormTablet,    sub: (l) => l.medsAddFormTabletSub),
  // capsule, syrup, drops, injection, inhaler, cream, sachet ...
];
```

The function-typed `name`/`sub` let the list live at top-level while still localizing at build time via `context.l10n`. (Alternative: a presentation-level `enum` + exhaustive `switch` extension — rejected as more boilerplate for no benefit; KISS.)

### Display row (the collapsed control)

- Wrap the row content in an **`InputDecorator`** with `InputDecoration(labelText: context.l10n.medsAddFormLabel)`. This reuses the global `inputDecorationTheme` (outlined, 4px radius, `outline`→`primary` border, floating label cut into the surface) — giving visual consistency with the name `TextField` directly above it **for free**, and the floating label without hand-rolling a `Stack`+`Positioned`. Set `isEmpty: false` so the label stays floated (the row always shows either the placeholder or a selection).
- Row content (a `Row`): leading **icon chip** (`Container`, `secondaryContainer` background, ~`shape-sm` rounded, icon in `onSecondaryContainer`) + an `Expanded` text column (name line `bodyLarge`/`onSurface`; sub line `bodySmall`/`onSurfaceVariant`) + trailing chevron wrapped in **`AnimatedRotation`** (0 → 0.5 turn when open).
- Wrap the whole `InputDecorator` in an `InkWell`/`GestureDetector` whose `onTap` toggles `_isOpen` via `setState`.
- **Before selection** (`_selectedIndex == null`): name line = `context.l10n.medsAddFormPlaceholder`, sub line empty, a neutral placeholder icon.

### Grid card (expanded)

- An **`AnimatedSize`** (implicit, ~250–300 ms, matches the design's `.28s`) whose child is **conditionally built**: `SizedBox.shrink()` when collapsed, the grid card when `_isOpen`. Building the grid only when open makes AC-3 ("title/options not present in the tree") cleanly testable and sidesteps the off-stage-finder pitfall (MEMORY Bug 020).
- Grid card: a `Container`/`Material` with `primaryContainer` background and rounded **bottom** corners (`shape-lg`), containing a title (`context.l10n.medsAddFormGridTitle`, uppercase, `primary`, `labelMedium`/bold) + the 2-column option layout.
- **2-column layout**: a `Column` of `Row`s, pairing the 8 options into 4 rows, each option wrapped in `Expanded` with a fixed gap between. _(Chosen over `GridView.count(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` to avoid `childAspectRatio` guesswork and intrinsic-height friction inside the outer `SingleChildScrollView`.)_
- **Option chip** (`.fpg-opt`): an `InkWell` over a `Container(BoxDecoration)`; unselected = `surfaceContainerLow`/`surface` bg with transparent border; **selected** = `primary` bg, `primary` border, icon + label in `onPrimary`. Built by mapping over `_medFormOptions` with the index compared to `_selectedIndex`.

### Selection behavior

`onTap` of an option: `setState(() { _selectedIndex = i; _isOpen = false; })`. This (a) highlights exactly one (index equality), (b) the display row re-reads `_medFormOptions[_selectedIndex]` for icon/name/sub, (c) collapses the grid. Matches the HTML `selectForm` (minus the out-of-scope `FORM_FIELDS` field-toggling).

### Insertion into the modal

In `_AddMedicationModalState.build`, add the picker into the existing `Column` between the name `TextField` and the `SizedBox(height:16)`+Save button, with spacing. The picker uses **no** `TextField` and **no** `FilledButton`, so spec-026's "exactly one `TextField` / one `FilledButton`" assertions stay green.

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Picker state ownership | Private `_MedicationFormPicker` `StatefulWidget` owning `_selectedIndex` + `_isOpen` | Single responsibility; keeps `_AddMedicationModalState` lean; precedent `_RouterErrorScreen` (`app_router.dart:105`) | State in `_AddMedicationModalState` (bloats modal state, mixes concerns) |
| Selection → parent | Not surfaced (no callback) this iteration | Save is a no-op; YAGNI/KISS — add the callback when data-save needs it | Add unused `onFormSelected` now (speculative generality) |
| Display-row outline + floating label | `InputDecorator` reusing `inputDecorationTheme` | Visual consistency with the name field; floating label + outline for free | Hand-rolled `Stack` + `Positioned` label + `Container` border (more code, drift from field styling) |
| Expand/collapse + caret | Implicit `AnimatedSize` + `AnimatedRotation` | No `AnimationController` → nothing to dispose (constitution dispose hygiene) | `AnimationController` + `SizeTransition`/`RotationTransition` (manual lifecycle, dispose burden) |
| Grid presence when collapsed | Conditionally build (shrink when closed) | Clean `findsNothing` for AC-3; avoids off-stage finder pitfall (MEMORY Bug 020) | Always-built + clipped (off-stage items break `find.text`) |
| 2-column layout | `Column` of `Row`s with `Expanded` pairs | Deterministic height; no aspect-ratio tuning inside a scroll view | `GridView.count(shrinkWrap, NeverScrollable)` (childAspectRatio guesswork) |
| Forms data | Presentation `_MedFormOption` + `final` list, l10n via closures | One source of truth, iterate to render, no domain coupling | Presentation `enum` + switch extension (more boilerplate); domain enum (out of scope) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Modify | Add `_MedFormOption` + `_medFormOptions` list + private `_MedicationFormPicker` `StatefulWidget`; insert it into the body `Column` between name field and Save; update library/class dartdoc. Imports: add `LucideIcons` (already imported), `AppLocalizations` type (via existing `l10n` extension import). |
| `lib/l10n/app_en.arb` | Modify | Add the 19 keys (§3.6) each with an `@`-description block (add a comma after the current last entry `prefsLoadRetry`). |
| `lib/l10n/app_de.arb` | Modify | Add the 19 keys with DE values (no `@` blocks). |
| `lib/l10n/app_uk.arb` | Modify | Add the 19 keys with UK values (no `@` blocks). |
| `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` | Regenerate | `flutter gen-l10n` emits the 19 new getters; do not hand-edit. |
| `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Modify | Add picker tests (AC-13 a–d); keep all spec-026 + locale tests unchanged. |

> **Addition discovered during planning** (not in spec §4 Affected Areas, but implied): no new files — all changes are modifications/regeneration of files already listed in the spec. No deviation.

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/meds.md` | Update (at `/finalize`) | Document the form picker (8 forms, expand/collapse, local selection, still no persistence) as iteration 2 of the add-medication form. |

No `docs/architecture.md` or `docs/api/` changes — internal presentation iteration, no architectural pattern change, no API.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `cream`/`sachet` Lucide names don't compile | Med | Low | `dart analyze`/build verifies; Material `Icons.*` fallback (spec §7, AC-5). Candidates: cream → `LucideIcons.container`/`Icons.healing`; sachet → `LucideIcons.package`. |
| Widget test can't find grid options | Med | Low | Conditional-build the grid → expand (tap), `pump()`, then `findsNWidgets(8)`; make assertions self-validating (MEMORY Bug 020). |
| `InputDecorator` label doesn't float / mis-renders without a real input | Low | Low | Pass `isEmpty: false`; verify on device (AC-16). Fallback: hand-rolled `Stack` label if `InputDecorator` misbehaves. |
| 19 keys × 3 locales — a missing locale key | Med | Low | Add all keys to all 3 ARBs in one task; `flutter gen-l10n` surfaces untranslated-message warnings against the EN template. |
| Expanded grid grows modal beyond viewport (small screens) | Low | Low | Body already a `SingleChildScrollView`; grid scrolls into view. |
| Future reviewer reads unconsumed selection as dead code | Low | Low | Inline dartdoc marks it visual-only iteration 2; Save stays no-op until data-save iteration. |

## Dependencies

None. No packages to install, no services, no environment variables. `pubspec.yaml` unchanged (uses existing `flutter`, `lucide_icons_flutter`, `flutter_localizations`/`intl`).

## Plan-Spec Cross-Reference

| AC | Covered by |
|----|-----------|
| AC-1 (placement below field, above Save) | Layer Map + "Insertion into the modal" |
| AC-2 (display row: label, icon chip, name, sub, chevron) | "Display row" |
| AC-3 (collapsed + placeholder on first open) | "Display row" (placeholder branch) + "Grid card" (conditional build) |
| AC-4 (tap toggles; title + 8 options 2-col; chevron state) | "Grid card" + `AnimatedRotation` |
| AC-5 (localized name + Lucide icon, Material fallback) | `_MedFormOption` list + §3.7 mapping + Risk row |
| AC-6 (select → highlight, update display, collapse) | "Selection behavior" |
| AC-7 (local setState, no Riverpod, Save stays no-op) | Technical Context + Key Decisions (state ownership) |
| AC-8 (presentation-only forms, no domain/data, pubspec unchanged) | Layer Map + "Presentation-only data shape" + Dependencies |
| AC-9 (19 keys in 3 ARBs) | File Impact (ARB rows) |
| AC-10 (`@`-meta en-only) | File Impact (en vs de/uk rows) |
| AC-11 (context.l10n, no `!`, theme colors) | Constitution Compliance rows |
| AC-12 (`dart analyze` clean) | Constitution Compliance + PostToolUse hook |
| AC-13 (widget tests a–d + 026 preserved) | File Impact (test row) + "Grid presence" decision |
| AC-14 (`flutter test`) | Test task verification |
| AC-15 (`flutter build apk --debug`) | Post-execution verification |
| AC-16 (manual theme/locale) | `/verify` code-read; theme-driven colors + context.l10n |

All 16 ACs have a clear implementation path.

## Supporting Documents

- No `research.md` — no external-stack signals (Lucide + all widgets in-stack).
- No `data-model.md` — the only new structure is presentation-only (documented inline above).
- No `contracts.md` — no API/backend.
