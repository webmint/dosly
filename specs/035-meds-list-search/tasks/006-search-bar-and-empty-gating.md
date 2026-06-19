# Task 006: Animated slide-in search bar + query-gated empty placeholder

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/screens/meds_screen.dart`, `lib/features/meds/presentation/widgets/medication_section.dart`
**Depends on**: 003
**Blocks**: 007
**Context docs**: None
**Review checkpoint**: Yes

**Description**:
Rebuild the search affordance as an animated slide-in bar over the app-bar region (matching the template `.appbar-search-wrap`), and gate the per-section "nothing found" placeholder on an active query. Keep the global zero-meds card and the two filter chips. Search stays inside the screen's own `AppBar`/`flexibleSpace` so the routing shell / bottom nav is untouched.

**Change details**:
- In `lib/features/meds/presentation/widgets/medication_section.dart`:
  - Add a `required bool queryActive` parameter to `MedicationSection`.
  - Render the `medsListSectionEmpty` placeholder **only when** `queryActive && items.isEmpty`; otherwise (empty + no query) render just the header (no placeholder). Header always renders; non-empty path unchanged.
- In `lib/features/meds/presentation/screens/meds_screen.dart`:
  - Replace the title↔`TextField` swap with an **animated slide-in search bar**: drive it with an `AnimationController` (or `AnimatedSwitcher`/`AnimatedSlide`), ~220 ms ease-out, sliding in from the trailing edge over the app-bar area; background `Theme.of(context).colorScheme.surfaceContainer`.
  - Bar contents in order: leading search icon (`LucideIcons.search`), the `TextField` (hint `l10n.medsListSearchHint`, no borders), and a trailing clear (`LucideIcons.x`) **inside the bar** (not in `AppBar.actions`).
  - Fade the title out while the bar is open (`AnimatedOpacity`); restore on close.
  - Request input focus **after** the open animation completes (e.g. on `AnimationStatus.completed` / post-frame), not via synchronous `autofocus`.
  - Closing (trailing clear) reverses the animation, clears `_searchController`/`_query`, and restores the title (keep `_closeSearch` semantics).
  - Keep the search toggle + clear tap targets ≥ 48 dp.
  - Pass `queryActive: _query.trim().isNotEmpty` to each `MedicationSection`.
  - Keep the global `_EmptyState` branch on `view.totalCount == 0` and the two-`FilterChip` row exactly as-is.

**Status**: Complete

**Done when**:
- [x] Opening search animates a slide-in bar (icon + field + inline clear) with a `surfaceContainer` background; the title fades.
- [x] Focus is requested after the animation, not synchronously on first frame.
- [x] Closing collapses the bar, clears the query, restores the title.
- [x] `MedicationSection` shows the per-section placeholder only when `queryActive && items.isEmpty`; an empty section with no query shows header only.
- [x] Global zero-meds `_EmptyState` (on `totalCount == 0`) and the All/Active chips still render.
- [x] `dart analyze` passes; `mounted` checked after any `await`; no `print`/`debugPrint`.

## Completion Notes
**Completed**: 2026-06-18
**Files changed**: `lib/features/meds/presentation/screens/meds_screen.dart`, `lib/features/meds/presentation/widgets/medication_section.dart`
**Contract**: Expects [3/3 verified] | Produces [3/3 verified]
**Code review**: APPROVE WITH WARNINGS → all 3 warnings fixed in a follow-up repair (W-1 animations promoted to State fields + disposed, no per-frame `CurvedAnimation`/`Tween`; W-3 `_openSearch` early-returns when `_searchAnim.isAnimating`; W-2 stale library doc updated).
**Notes**: Animated bar lives in `AppBar.flexibleSpace` (overlays title/actions, leaves the `bottom:` divider + routing shell untouched), `SlideTransition` offset (1,0)→0 easeOut 220ms, `surfaceContainer` bg, leading search icon + borderless `TextField` + inline `LucideIcons.x` clear (48dp). Title/search-button fade via `ReverseAnimation(_searchAnim)`. Focus deferred via `_searchAnim.forward().then(...)` with `if (!mounted) return`. `IgnorePointer` gates the collapsed bar and the toggle. **Expected**: the old `meds_screen_test` search-interaction tests go red (ambiguous `find.byIcon(search)` — bar adds a 2nd search icon); Task 007 rewrites them. Non-search tests (26) stay green.

## Contracts

### Expects
- `buildMedsListView` returns score-ranked sections under an active query and `MedsListView.totalCount` = pre-filter count (Task 003).
- `MedicationSection` currently renders `medsListSectionEmpty` whenever `items.isEmpty`.
- `medicationsListProvider` exposes `AsyncValue<List<Medication>>`; l10n keys `medsListSearchHint`, `medsListSectionEmpty`, `medsListEmptyTitle`, `medsListEmptyBody` exist.

### Produces
- `MedicationSection` constructor declares `required bool queryActive`; the placeholder renders only under `queryActive && items.isEmpty`.
- `meds_screen.dart` builds the search affordance with an animation driver and `colorScheme.surfaceContainer` background, places the clear control inside the search bar, and passes `queryActive: _query.trim().isNotEmpty` to `MedicationSection`.
- The `totalCount == 0` global `_EmptyState` branch and the two `FilterChip`s remain.

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4, AC-10, AC-11, AC-12, AC-13
