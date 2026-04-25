# Plan: Settings Screen

**Date**: 2026-04-25
**Spec**: specs/008-settings-screen/spec.md
**Status**: Approved

## Summary

Create an empty `SettingsScreen` widget (identical pattern to `MedsScreen`/`HistoryScreen`) with a localized AppBar title and 1-px divider, register `/settings` as a sibling `GoRoute` outside the `StatefulShellRoute` (same slot as `/theme-preview`), and enable the existing gear `IconButton` on `HomeScreen` to `context.push('/settings')`.

## Technical Context

**Architecture**: Presentation layer only — no domain, no data, no state management needed.
**Error Handling**: N/A — no fallible operations.
**State Management**: N/A — stateless screen.

## Constitution Compliance

- §2.1 Layer Boundaries: Compliant — presentation-only, no domain/data layers created.
- §2.2 File Organization: Compliant — `lib/features/settings/presentation/screens/settings_screen.dart` follows the per-feature structure.
- §3.1 No `!` null assertion: Compliant — uses `context.l10n` extension (centralized `!` site).
- §3.7 No debug artifacts: Compliant — no `print()`.
- Cross-feature imports: `HomeScreen` imports `go_router` (already does) to push `/settings`. No cross-feature widget import.

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Presentation | Empty settings screen | `lib/features/settings/presentation/screens/settings_screen.dart` (new) |
| Presentation | Enable gear icon navigation | `lib/features/home/presentation/screens/home_screen.dart` (modify) |
| Core/Routing | Add `/settings` GoRoute | `lib/core/routing/app_router.dart` (modify) |
| L10n | Add `settingsTitle` key | `lib/l10n/app_en.arb`, `app_uk.arb`, `app_de.arb` (modify) |
| Tests | Screen widget test | `test/features/settings/presentation/screens/settings_screen_test.dart` (new) |
| Tests | Router integration test | `test/core/routing/app_router_test.dart` (modify) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Route type | Sibling `GoRoute` outside `StatefulShellRoute` | Settings is a full-screen push, not a tab branch. No bottom nav on settings screen. Same pattern as `/theme-preview`. | Adding as a 4th shell branch — wrong UX (settings shouldn't be a tab) |
| Navigation method | `context.push('/settings')` | Push preserves shell branch stack underneath. Back button returns to Home. | `context.go('/settings')` — would replace the shell stack, breaking back navigation |
| L10n key | New `settingsTitle` separate from `settingsTooltip` | Different purpose: screen title vs icon tooltip. May diverge in future. | Reuse `settingsTooltip` — would conflate two distinct UI roles |
| AppBar back button | Flutter automatic `BackButton` via GoRouter push | GoRouter's push route automatically shows the AppBar back button. No manual `leading:` needed. | Manual `leading: IconButton(icon: LucideIcons.arrowLeft, ...)` — unnecessary when framework handles it |
| No `home_screen_test.dart` | Skip creating a dedicated HomeScreen test file | No existing test file for HomeScreen. The gear-icon navigation is covered by a new router integration test (push `/settings` from Home context, verify SettingsScreen renders and back works). Testing the `IconButton.onPressed` callback in isolation adds little value over the router test. | Create `home_screen_test.dart` — overkill for a one-line wiring change; router test covers the behavior end-to-end |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/settings/presentation/screens/settings_screen.dart` | Create | `SettingsScreen` StatelessWidget — Scaffold + AppBar with `context.l10n.settingsTitle`, 1-px divider, `SizedBox.shrink()` body |
| `lib/core/routing/app_router.dart` | Modify | Add `GoRoute(path: '/settings', builder: → SettingsScreen())` as sibling to the existing `/theme-preview` route |
| `lib/features/home/presentation/screens/home_screen.dart` | Modify | Change gear `IconButton.onPressed` from `null` to `() => context.push('/settings')` |
| `lib/l10n/app_en.arb` | Modify | Add `"settingsTitle": "Settings"` with description |
| `lib/l10n/app_uk.arb` | Modify | Add `"settingsTitle": "Налаштування"` |
| `lib/l10n/app_de.arb` | Modify | Add `"settingsTitle": "Einstellungen"` |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | Create | Widget test: locale switching (en/uk/de/unsupported), AppBar shape (divider, no actions), empty body — same pattern as `meds_screen_test.dart` |
| `test/core/routing/app_router_test.dart` | Modify | Add Test 6: push `/settings` → SettingsScreen renders without AppBottomNav → back returns to Home with AppBottomNav. Same pattern as Test 5 (`/theme-preview`). |

### Documentation Impact

No documentation changes expected — internal implementation only. Presentation-only feature following established patterns.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Bottom nav visible on settings screen | Low | Medium | `/settings` is a sibling GoRoute outside the shell (same as `/theme-preview`). Test 5 pattern already validates this for `/theme-preview`; new Test 6 does the same for `/settings`. |
| L10n codegen fails after ARB changes | Low | Low | Run `flutter gen-l10n` (implicit in `flutter pub get` / `flutter test`) and verify generated files. |
| Back navigation breaks shell state | Low | Low | `context.push` preserves the shell's branch stack. Router test verifies round-trip. |

## Dependencies

None — no new packages, services, or configuration needed.
