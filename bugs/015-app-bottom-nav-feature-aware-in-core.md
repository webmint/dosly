# Bug 015: `AppBottomNav` is feature-aware but lives in `core/widgets/`

**Status**: Open
**Severity**: Warning
**Source**: audit (audits/2026-04-30-audit.md)
**Reported**: 2026-04-30
**Fixed**:

## Description

Constitution §2.1: "Shared utilities live in `lib/core/`. Anything in `core/`
must be feature-agnostic."

`lib/core/widgets/app_bottom_nav.dart` hardcodes the three feature destinations
(Today/Meds/History): destination identity, Lucide icon, and localized label
key all live in `core/widgets/`. If a future feature (e.g. Reports, Reminders,
Profile) is added or the IA shifts, the change must be made inside `core/widgets/`.

The widget's dartdoc describes itself as "router-agnostic" but the
destinations are not parameterized — only `selectedIndex` and
`onDestinationSelected` are. The widget is not actually reusable in isolation
and assumes a single hardcoded shell composition.

## File(s)

| File | Detail |
|------|--------|
| lib/core/widgets/app_bottom_nav.dart | Lines 1–84 (entire file, hardcoded destinations at lines 65–77) |
| lib/core/routing/app_shell.dart | (composition root that supplies the destination order) |

## Evidence

`lib/core/widgets/app_bottom_nav.dart:60–78`:
```
        const Divider(height: 1, thickness: 1),
        NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(LucideIcons.house),
              label: l.bottomNavToday,
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.pill),
              label: l.bottomNavMeds,
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.activity),
              label: l.bottomNavHistory,
            ),
          ],
        ),
```

Reported by audit (architect F13 — original Evidence quote was discarded by
verbatim-quote validation due to `...` ellipsis, but the underlying observation
is verified against the file).

## Fix Notes

Two options (to be confirmed in `/fix`):

**Option A (preferred — relocate):** move `app_bottom_nav.dart` to
`lib/app/widgets/app_bottom_nav.dart` (the composition-root layer). The app's
overall IA is not "core" infrastructure but app-shell concern. `core/` stays
genuinely feature-agnostic.

**Option B (parameterize):** change `AppBottomNav({required List<NavigationDestination>
destinations, required this.selectedIndex, required this.onDestinationSelected})`
and move the concrete destination list into `app_shell.dart` (which already
imports the features). Makes the widget actually reusable and testable in
isolation without `AppLocalizations`.

Option A is structurally cleaner but creates a new top-level directory
(`lib/app/`) which doesn't yet exist. Option B is more conservative and
matches the dartdoc's existing claim of "router-agnostic". User decision.
