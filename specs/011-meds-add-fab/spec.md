# Spec: Meds Screen Add-FAB and Placeholder Modal

**Date**: 2026-04-29
**Status**: Complete (shipped 2026-04-30; modal type revised post-implementation per user feedback — see §3.2)
**Author**: Claude + Webmint

## 1. Overview

Add a Material 3 FloatingActionButton (FAB) to the Meds tab and wire it to open
an empty placeholder **full-screen modal** that shows only a localized title in
its AppBar. This lays the visible UI scaffolding for the future "add medication"
flow without yet implementing any add-medication logic — the modal body remains
empty until the real flow is specified in a later feature. The FAB and modal
must respect both theme switching (light/dark, manual/system) and the app's
existing localization contract (en/de/uk).

> **Modal type note (2026-04-30)**: The original spec and plan chose
> `showModalBottomSheet` for the modal. After implementation the user
> reported "look absolutely different from HTML" and clarified: not a sheet,
> not a registered go_router screen — a full-screen modal route. The
> implementation was refactored to use
> `Navigator.push(MaterialPageRoute(fullscreenDialog: true, ...))` with
> `rootNavigator: true` so the modal covers the AppShell's bottom nav. The
> body is now a `Scaffold(appBar: AppBar(leading: back-arrow IconButton,
> title: Text(medsAddTitle)), body: SizedBox.shrink())`. AC numbering kept
> stable; the AC text below was updated in-place to reflect the shipped
> behavior.

## 2. Current State

**Meds screen** (`lib/features/meds/presentation/screens/meds_screen.dart:22`)
is a `StatelessWidget` with a `Scaffold` whose `appBar` is a Material 3 `AppBar`
showing the localized `bottomNavMeds` title (with a 1-px `outlineVariant`
divider as `bottom`) and whose `body` is `SizedBox.shrink()`. There is no
`floatingActionButton`, no modal trigger, and no associated provider/state.

**Routing shell** (`lib/core/routing/app_shell.dart:33`) wraps each branch
screen (Today / Meds / History) inside an outer `Scaffold` whose
`bottomNavigationBar` is `AppBottomNav`. Each branch screen brings its own
inner `Scaffold` (and therefore its own `AppBar` and `floatingActionButton`
slot). When a FAB is added to `MedsScreen`'s inner `Scaffold`, Flutter renders
it inside the inner scaffold above the inner body and below the outer
`AppBottomNav` — which matches the HTML mock's `bottom: calc(var(--nav-h) +
16px)` positioning naturally with no manual offset math.

**Theme** (`lib/core/theme/app_theme.dart:81`) already declares a
`floatingActionButtonTheme` with `backgroundColor: scheme.primaryContainer`,
`foregroundColor: scheme.onPrimaryContainer`, and `elevation: 0`. This is a
direct one-to-one match with the HTML token mapping
(`background: var(--md-primary-container)`,
`color: var(--md-on-primary-container)`) used in `dosly_m3_template.html:355`.
Both light and dark schemes are defined in
`lib/core/theme/color_scheme_light.dart` and
`lib/core/theme/color_scheme_dark.dart`, so a `FloatingActionButton` with no
explicit color overrides will automatically swap when the theme switches via
the existing `settingsProvider` → `themeMode` chain.

**Lucide icon set** (`pubspec.yaml` → `lucide_icons_flutter: ^3.1.12`)
exposes `LucideIcons.plus` and is already used in
`lib/features/theme_preview/presentation/screens/theme_preview_screen.dart:68`
for an identical FAB shape. The HTML mock's "+" SVG path
(`M12 5v14M5 12h14`) is the canonical Lucide `plus` glyph — matched 1:1.

**Localization** is wired through `flutter gen-l10n` against three ARB files
(`lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_uk.arb`) and
consumed via the `context.l10n` extension defined in
`lib/l10n/l10n_extensions.dart`. The active locale is driven by
`settingsProvider.select((s) => s.effectiveLocale)` in `lib/app.dart`. Any new
strings added below MUST be declared in all three ARB files plus the `@`
description metadata block (en only) per the existing pattern.

**Modal patterns**: The codebase currently has zero `showDialog` /
`showModalBottomSheet` / `Dialog` usages — this is the first modal in the
project. Material 3 conventions for "add" entry-points on mobile are a
bottom sheet, which is what the HTML mock implies via the FAB → `openAdd()`
handler.

**Tests**: `test/features/meds/presentation/screens/meds_screen_test.dart`
exists and asserts the placeholder body is empty. Adding a FAB will require
that test to be extended (or its assertions kept narrowly scoped so they
don't break on the new FAB widget being present).

**Known pitfall reference (MEMORY.md, Feature 006)**: `AppLocalizations.of`
returns nullable, so any new localized strings must be reached via the
existing `context.l10n` extension getter — never via `!` at the call site.

## 3. Desired Behavior

1. **FAB on the Meds screen**
   - `MedsScreen` gains a `floatingActionButton` of type `FloatingActionButton`
     (the standard 56×56 M3 FAB, NOT `FloatingActionButton.extended`,
     `.large`, or `.small`).
   - Icon: `Icon(LucideIcons.plus)`. No explicit `size`, `color`, or
     `backgroundColor` — defaults flow from the global
     `floatingActionButtonTheme`.
   - `tooltip`: localized string from the new `medsAddFabTooltip` ARB key.
   - The FAB sits at `Scaffold`'s default end-float position
     (`floatingActionButtonLocation: FloatingActionButtonLocation.endFloat`,
     which is also the default — no override needed).
   - Other Meds-screen elements (AppBar, bottom divider) are unchanged.

2. **Tap behavior** _(revised 2026-04-30 — was `showModalBottomSheet`)_
   - On tap, the FAB's `onPressed` calls
     `Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const AddMedicationModal()))`.
   - `rootNavigator: true` walks above the `StatefulShellRoute` so the
     modal covers the AppShell's bottom navigation bar (full-screen).
   - `fullscreenDialog: true` gives the modal a slide-up entrance and
     marks the route as a modal dialog (vs. a regular page push).
   - The modal widget (`AddMedicationModal`) is a `Scaffold` whose
     `appBar` is `AppBar(leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => Navigator.of(context).pop(), tooltip: MaterialLocalizations.of(context).backButtonTooltip), title: Text(context.l10n.medsAddTitle))`.
   - The Scaffold body is `SizedBox.shrink` — intentionally empty until
     the real Add-medication form ships in a future feature.
   - All visual chrome (AppBar background/foreground/elevation,
     status-bar styling) flows from the existing global theme. No
     explicit color/shape/elevation parameters at the call site or in
     the modal widget.
   - Dismissal: tap the back-arrow IconButton (calls
     `Navigator.of(context).pop()`), or use the system back gesture/button.

3. **Theme switching**
   - The FAB MUST render
     `colorScheme.primaryContainer` background and
     `colorScheme.onPrimaryContainer` foreground in both light and dark
     themes without any code change at the call site.
   - The modal's `AppBar` MUST render the M3 default surface tint
     (driven by the global theme's `appBarTheme` / `colorScheme`) in
     both light and dark themes — no explicit `backgroundColor` /
     `foregroundColor` overrides at the call site.
   - Cycling the app theme via the existing Settings → Appearance →
     SegmentedButton (Light / Dark) MUST update the FAB and (if the
     modal is open) the modal AppBar colors live, with no widget-tree
     rebuild required beyond the existing `settingsProvider` reactivity.

4. **Localization**
   - Two new ARB keys:
     - `medsAddFabTooltip` — accessibility/long-press tooltip on the FAB.
       English: "Add medication". German: "Medikament hinzufügen". Ukrainian:
       "Додати ліки".
     - `medsAddTitle` — title text shown at the top of the empty modal.
       English: "Add medication". German: "Medikament hinzufügen". Ukrainian:
       "Додати ліки".
   - Both keys MUST exist in all three ARB files and have a single
     `@key` description block in `app_en.arb` (the template locale).
   - Switching the language via Settings → Language MUST update both the
     tooltip and the modal title live for any subsequent open of the
     modal. (A modal that is already open during the locale change is not
     in scope — see §6.)
   - String values MUST be reached through the existing `context.l10n`
     extension. No `AppLocalizations.of(context)!` at the call site.

5. **Accessibility**
   - The FAB has a non-empty `tooltip` (covered by §3.1).
   - Default Flutter `Semantics` for `FloatingActionButton` and
     `showModalBottomSheet` is sufficient — no custom `Semantics` wrapper.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Meds presentation — screen | `lib/features/meds/presentation/screens/meds_screen.dart` | Add `floatingActionButton`; add `_openAddMedicationModal(BuildContext)` private helper that calls `Navigator.push(MaterialPageRoute(fullscreenDialog: true, ...))` via `rootNavigator: true`. _(Originally specced as `_openAddMedicationSheet` calling `showModalBottomSheet`; revised 2026-04-30.)_ |
| Meds presentation — modal widget | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | **Create new**: a `StatelessWidget` named `AddMedicationModal` returning a `Scaffold(appBar: AppBar(leading: back-arrow IconButton, title: Text(medsAddTitle)), body: SizedBox.shrink())`. _(Originally specced as `add_medication_sheet.dart` / `AddMedicationSheet` with a padded Column+Text body; revised 2026-04-30.)_ |
| L10n — English template | `lib/l10n/app_en.arb` | Add `medsAddFabTooltip` and `medsAddTitle` plus `@`-description metadata for each. |
| L10n — German | `lib/l10n/app_de.arb` | Add the two keys with translated values. |
| L10n — Ukrainian | `lib/l10n/app_uk.arb` | Add the two keys with translated values. |
| L10n — generated bindings | `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_de.dart`, `lib/l10n/app_localizations_uk.dart` | Regenerated by `flutter gen-l10n` (do not hand-edit). |
| Meds tests — screen | `test/features/meds/presentation/screens/meds_screen_test.dart` | Extend to assert FAB is present, has the localized tooltip, and tapping it opens a `BottomSheet` whose visible text equals the localized title. |
| Meds tests — modal widget | `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | **Create new**: assert the modal renders an `AppBar` containing the localized `medsAddTitle` for the active locale; assert the AppBar leading is an `IconButton` whose icon is `LucideIcons.arrowLeft`; assert the Scaffold `body` is `SizedBox.shrink`. _(Originally specced as `add_medication_sheet_test.dart` asserting a single Text child; revised 2026-04-30 — files renamed via `git mv`.)_ |

No changes to the routing shell, the theme, the `lucide_icons_flutter`
dependency, the `settingsProvider`, or any domain/data layer.

## 5. Acceptance Criteria

- [ ] **AC-1**: `MedsScreen` exposes a `FloatingActionButton` that renders a
      `LucideIcons.plus` icon and has a non-empty `tooltip`.
- [ ] **AC-2**: The FAB's background and foreground colors come from the
      global `floatingActionButtonTheme` — i.e. no explicit
      `backgroundColor` or `foregroundColor` parameters are passed at the
      `FloatingActionButton` constructor.
- [x] **AC-3** _(revised 2026-04-30)_: Tapping the FAB calls
      `Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const AddMedicationModal()))`.
      _(Was: calls `showModalBottomSheet<void>` whose builder returns
      `AddMedicationSheet`.)_
- [x] **AC-4** _(revised 2026-04-30)_: `AddMedicationModal` renders the
      localized `medsAddTitle` inside its `AppBar.title`. The Scaffold
      body is `SizedBox.shrink` — no buttons, form fields, or other
      interactive controls beyond the AppBar's back-arrow IconButton
      leading. _(Was: `AddMedicationSheet` renders one Text and zero
      interactive controls.)_
- [x] **AC-5** _(revised 2026-04-30)_: The modal title uses the M3
      default `AppBar.title` style (which the AppBar derives from
      `Theme.of(context).textTheme.titleLarge` by default; no explicit
      style override at the call site). _(Was: title text uses
      `Theme.of(context).textTheme.titleLarge` directly.)_
- [x] **AC-6** _(revised 2026-04-30)_: The `MaterialPageRoute` is
      constructed with `fullscreenDialog: true` and pushed via
      `rootNavigator: true`. No explicit `backgroundColor` / `shape` /
      `elevation` overrides on the `AppBar`, `Scaffold`, or
      `IconButton`. _(Was: `showModalBottomSheet` with `useSafeArea:
      true` and no chrome overrides.)_
- [ ] **AC-7**: Two new ARB keys `medsAddFabTooltip` and `medsAddTitle`
      exist in all three ARB files (`app_en.arb`, `app_de.arb`,
      `app_uk.arb`) with the values defined in §3.4.
- [ ] **AC-8**: `app_en.arb` includes `@medsAddFabTooltip` and
      `@medsAddTitle` description metadata blocks per the existing
      convention.
- [ ] **AC-9**: All occurrences of the new strings in widget code are
      reached via `context.l10n` (no `AppLocalizations.of(context)!` at
      the call site).
- [ ] **AC-10**: `dart analyze` passes on all changed/created files with
      zero warnings or errors (strict-mode lint config preserved).
- [ ] **AC-11**: The existing `meds_screen_test.dart` no longer asserts
      `body == SizedBox.shrink` (or any equivalent that the FAB would
      break), and its new assertions cover: (a) FAB present, (b) tooltip
      equals the localized `medsAddFabTooltip` for the test locale, (c)
      tapping the FAB pumps a frame and `find.text(<localized
      medsAddTitle>)` resolves to one widget.
- [ ] **AC-12**: A new `add_medication_sheet_test.dart` asserts the
      sheet renders the localized title and contains no other text or
      button widgets.
- [ ] **AC-13**: `flutter test` passes for the full project (existing
      tests + the meds tests above).
- [ ] **AC-14**: `flutter build apk --debug` succeeds.
- [ ] **AC-15** _(manual, gated by /verify reading code only)_: Running
      the app on a device or emulator and toggling Settings →
      Appearance between Light and Dark while the meds tab is visible
      shows the FAB swapping to the matching `primaryContainer` /
      `onPrimaryContainer` colors with no visual glitch.
- [ ] **AC-16** _(manual)_: Running the app and switching Settings →
      Language between English / Deutsch / Українська updates both the
      FAB tooltip (revealed via long-press) and the bottom-sheet title
      to the corresponding localized string the next time the modal is
      opened.

## 6. Out of Scope

- NOT included: any actual "add medication" functionality (form, fields,
  validation, persistence, drift writes, providers, use cases). The
  modal stays deliberately empty.
- NOT included: any `Medication` domain entity, repository, data source,
  or use case — those will land in a separate spec when the real add
  flow is specified.
- NOT included: a "Cancel" or "Close" button inside the modal. Dismissal
  uses scrim tap, drag-down, or system back only.
- NOT included: changing the FAB shape, position, or
  `floatingActionButtonLocation` away from `endFloat`.
- NOT included: any change to `AppBottomNav`, the routing shell, or the
  bottom-nav icons.
- NOT included: extracting the FAB into a shared `lib/core/widgets/` —
  it is a Meds-feature widget for now and may be promoted later if a
  second feature needs it.
- NOT included: handling the case where the modal is open at the moment
  the user changes the locale or theme. The modal will keep whatever
  strings/colors were captured when it was opened; closing and reopening
  picks up the new values. (Material handles theme changes
  automatically; locale text changes mid-modal would require listening
  to `settingsProvider` from inside the sheet, which is unjustified
  complexity for an empty placeholder.)
- NOT included: integration tests that drive theme/locale changes
  through Settings and assert the FAB updates — covered by AC-15/AC-16
  manually since theme/locale propagation is already proven by Features
  009 and 010 tests.
- NOT included: animation, transitions, or "shared element" hero
  treatment between the FAB and the modal.

## 7. Technical Constraints

- **Constitution compliance**:
  - No `!` null assertion in widget code (use `context.l10n`).
  - No Flutter imports in `domain/`. (Not relevant here — no domain
    code is touched.)
  - All new public widgets/classes need dartdoc `///` comments.
  - `dart analyze` must pass with zero issues; lint-suppression
    comments are forbidden (MEMORY.md, Feature 010 lesson).
- **Theme**: must use the existing global
  `floatingActionButtonTheme` — do not pass explicit colors at the
  call site. (MEMORY.md, Feature 005: "Flutter built-in widgets
  deliver M3 theming for free; don't hard-code colors.")
- **Icons**: must use `LucideIcons.plus` from
  `lucide_icons_flutter`, consistent with the existing precedent in
  `theme_preview_screen.dart:68`. Do not introduce a new icon
  package.
- **Localization**: must follow the existing ARB pattern — keys in all
  three locales, `@` description metadata only in `app_en.arb`,
  consumption via `context.l10n`.
- **No new dependencies**: `pubspec.yaml` is not modified.
- **Test framework**: `flutter_test` + `mocktail` per the project
  convention. No new test deps.

## 8. Open Questions

- _(resolved 2026-04-30)_ Modal type was originally specced as
  `showModalBottomSheet`. After implementation the user clarified the
  intent was a full-screen modal route, not a bottom sheet. Refactored
  to `Navigator.push(MaterialPageRoute(fullscreenDialog: true, ...))` via
  `rootNavigator: true`. Lesson recorded in MEMORY.md: when a user says
  "modal" alongside an HTML reference, default-clarify to full-screen
  modal route, not bottom sheet.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Existing `meds_screen_test.dart` asserts on `SizedBox.shrink` body and breaks when the FAB is added | High | Low | Update the test in the same task that adds the FAB so the breakage is internal to a single task. |
| Adding a FAB inside an inner `Scaffold` (under the outer `AppShell` `Scaffold`) shifts the FAB above the outer `bottomNavigationBar` in an unexpected way | Low | Low | Visually verify on iOS + Android emulators during AC-15; if the offset is wrong, set `floatingActionButtonLocation: FloatingActionButtonLocation.endFloat` explicitly (it's the default but stating it documents intent). The HTML mock's `bottom: calc(var(--nav-h) + 16px)` is what nested scaffolds produce naturally. |
| Translator copy for `medsAddTitle` in DE/UK lands wrong | Low | Low | Use the strings supplied in §3.4 verbatim; the user is the translator and can correct in a follow-up if needed. |
| New `showModalBottomSheet` becomes a copy-paste template that future "add" features extend in-place rather than replacing | Med | Med | Mark `AddMedicationSheet` clearly as a placeholder in its dartdoc, and add a TODO with a reference to the future "real add flow" spec slot ("Replace body when spec NNN-add-medication-form ships"). Constitution forbids bare TODOs, so include the full context in the comment. |
| The FAB and modal display correctly in light theme but a missing `surfaceContainerLow` mapping breaks the dark-mode sheet background | Low | Med | The existing `colorScheme.surfaceContainerLow` is already defined in both `color_scheme_light.dart` and `color_scheme_dark.dart` (verified — this is a Material Theme Builder export); manual AC-15 check covers the sheet visually. |
