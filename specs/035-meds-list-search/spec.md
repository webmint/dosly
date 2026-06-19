# Spec: Meds-List Search & Empty-State Fidelity

**Date**: 2026-06-18
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

Bring the medications-list screen's **search** and **empty-state** behaviour in line with the `#s-meds` design in `dosly_m3_template.html`, and upgrade name matching from a plain case-insensitive **substring** filter to **typo-tolerant ranked fuzzy** matching (Levenshtein-based) performed in-memory over the already-reactive list, with matches ordered by score. Completed-course tiles gain the design's de-emphasised treatment (dimmed + neutral badge + grey status chip). This is a **presentation + view-model** change only — the list is already wired to the drift database reactively, and there is **no schema change and no DB-level query change**.

Grounded in `research/2026-06-18-meds-list-search.md` (codebase + design-auditor findings).

## 2. Current State

The meds-list read slice shipped in spec **034-meds-list** (Status: Complete; 19/19 ACs, 481/481 tests). What exists today:

- **Reactive DB read (already wired)** — `MedicationLocalDataSource.watchAllMedications()` (`lib/features/meds/data/datasources/medication_local_data_source.dart:57`) runs a watched left-outer join of `medications ⨝ time_slots` that re-emits on any change to either table; `MedicationRepositoryImpl` wraps it as `Stream<Either<Failure, List<Medication>>>`; `medicationsList` (`lib/features/meds/presentation/providers/medication_providers.dart:65`) folds each emission into `AsyncValue<List<Medication>>`. **The list is fully DB-backed and live; "wire to DB" is already done.**
- **Search (substring, in-memory)** — `buildMedsListView` (`lib/features/meds/presentation/view_models/meds_list_view_model.dart:103`) filters the loaded list with `item.medication.name.toLowerCase().contains(normalizedQuery)` (line 130–136). Results are always sorted alphabetically (`_byNameCaseInsensitive`, line 169) regardless of query. `totalCount` is recorded **before** filter/search to distinguish empty states. Pipeline order: derive → search → filter (all/active) → group → sort.
- **Search UI (title-swap, no animation)** — `MedsScreen` (`lib/features/meds/presentation/screens/meds_screen.dart`) toggles `_searchOpen`; when open it **replaces** the `AppBar.title` Text with a bare `TextField` (`autofocus: true`, prefix search icon) and **replaces** the trailing search `IconButton` in `actions` with a close (×) `IconButton` (lines 99–135). No slide-in animation, no overlay, no background change; the × lives in `actions`, not inside the field.
- **Filter chips** — two `FilterChip`s (All / Active) via `_FilterChipRow` (lines 213–282); Archive deliberately deferred (needs schema migration, per spec 034 §6).
- **Empty states** — a **global** centered `_EmptyState` card (title + body) renders when `view.totalCount == 0` (lines 173–178). `MedicationSection` (`lib/features/meds/presentation/widgets/medication_section.dart:50`) renders the `medsListSectionEmpty` ("Нічого не знайдено") placeholder **whenever `items.isEmpty`** — including at rest with no active query (a divergence from the design, which shows it only during search).
- **Tiles** — `MedicationTile` (`lib/features/meds/presentation/widgets/medication_tile.dart`) renders an icon badge coloured by **type only** (continuous → `primaryContainer`, course → `tertiaryContainer`; lines 49–52), name, `dose · times · stock` subtitle, and chips. Completed courses render at **full opacity** with the active badge and a `surfaceContainerHighest` status chip (line 212) — visually indistinguishable from active. `_TileBody` renders `_StatusChip` **then** `_TypeChip` (lines 119–121) — reversed from the design, which puts the course-day chip first for course tiles.
- **l10n** — existing keys cover everything needed: `medsListTitle`, `medsListSearchHint`, `medsListSearchTooltip`, `medsListSectionContinuous`/`Course`, `medsListSectionEmpty`, `medsListEmptyTitle`/`Body`, `medsListStatusActive`/`Completed`, `medsListType*` (×3 locales: en/de/uk).
- **No fuzzy/search dependency** in `pubspec.yaml`.

**Design reference** — `dosly_m3_template.html` `#s-meds`: markup lines ~1838–1982; search CSS `.app-bar-search`/`.appbar-search-wrap`/`.search-input`/`.search-clear` ~1170–1207; `.sec-empty` (`display:none` → `.visible` only while searching) ~1206–1207; `.f-chip` ~702–720; tiles `.mlt`/`.med-iconify`/`.s-chip` (search file); JS `toggleSearch`/`clearSearch`/`filterMeds` ~2915–2985 (note: the template's own matcher is substring `data-med.includes(q)` — this spec **deliberately exceeds** the template by making it fuzzy).

## 3. Desired Behavior

### 3.1 Animated slide-in search bar
- The search affordance expands as an **animated slide-in bar** that covers the app-bar region (slide in from the trailing edge, ≈220 ms, ease-out), rather than swapping the title for a bare field.
- The expanded bar contains, in order: a **leading search icon**, the **text input** (hint = `medsListSearchHint`), and a **trailing clear (×)** control **inside the bar** (not in the app-bar `actions`).
- The bar background uses the M3 **`surfaceContainer`** token (matching `.appbar-search-wrap { background: var(--md-surface-container) }`).
- While the bar is open the **title fades out**; when collapsed the title is restored.
- Input **focus is requested after the open animation completes** (so the keyboard/caret appears once the bar is in place).
- Tapping the trailing × (or otherwise closing search) **collapses the bar with the reverse animation, clears the query, and restores the title** — returning the list to its filter-respecting, unsearched state.
- Tap targets for the search toggle and clear control remain **≥ 48 dp**.

### 3.2 Typo-tolerant ranked fuzzy matching (in-memory, pure)
- Name matching becomes **typo-tolerant fuzzy** (Levenshtein / normalized edit-distance similarity), **case-insensitive**, over `Medication.name`. It runs **in-memory in the pure view model** over the already-loaded reactive list — **no DB query, no schema change**.
- A medication is **included** when either:
  - its name contains the query as a case-insensitive substring (fuzzy must never regress today's exact-substring behaviour), **or**
  - its name is a sufficiently close fuzzy match to the query (similarity at or above a tuned threshold).
  - Clearly unrelated names (below threshold) are **excluded**.
- A **blank/whitespace-only query** disables matching entirely (the full, filter-respecting list shows) — unchanged from today.
- **Ordering**: while a query is active, items **within each section** are ordered by **descending match score**, ties broken by case-insensitive name ascending. With no active query, ordering is **case-insensitive name ascending** (today's behaviour).
- Search is applied **before** the All/Active filter (unchanged pipeline order); fuzzy results still respect the active filter.
- The matcher/scorer is a **pure function** (no Flutter, no drift, no `DateTime.now()`), unit-testable with fixed inputs.

### 3.3 Empty / "nothing found" states
- **Global zero-meds card (kept)**: when there are **no medications in the database at all** (`totalCount == 0`), the existing centered `_EmptyState` card (`medsListEmptyTitle` + `medsListEmptyBody`, guidance to tap **+**) shows and takes precedence over sections. This is retained as deliberate first-run UX (not in the template, but a justified addition).
- **Per-section placeholder gated on search**: the per-section "Нічого не знайдено" placeholder (`medsListSectionEmpty`) renders **only when a search query is active AND that section has zero matches**. With **no active query**, an empty section shows **no placeholder** (header only) — matching the template's `.sec-empty` toggle (`q.length>0 && !hasVisible`).
- **No-match across both sections**: when an active query matches nothing in either section, **both** section headers render, **each** with its own "Нічого не знайдено" placeholder beneath it (per-section, template-faithful — not a single consolidated message).
- Section **headers always render** (both Continuous and Course) whenever the global card is not shown, regardless of section emptiness.
- Loading and error states are unchanged (all three `AsyncValue.when` branches still handled).

### 3.4 De-emphasised completed-course tiles (full, audit-faithful)
For a tile whose derived `activity == MedicationActivityStatus.completed`:
- **Dim** the whole tile to ≈ **0.65 opacity** (matching the template's `opacity:.65` archived treatment).
- **Icon badge** uses the **neutral** variant — `surfaceVariant` background / `onSurfaceVariant` foreground (instead of the course `tertiaryContainer`).
- **Status chip** uses the grey token — **`surfaceVariant`** background / `onSurfaceVariant` foreground (replacing the current `surfaceContainerHighest`).
- Active medications are unchanged.

### 3.5 Course-tile chip order (design alignment)
- For **course** tiles, the **type chip (Day X/Y or Paused) renders first, then the status chip** — matching the design (`<span class="s-chip teal">День 7/30</span><span class="s-chip green">Активний</span>`). Continuous tiles keep status-then-type (design shows `Активний` then `постійний`, i.e. status first). Net rule: render in the design's documented order per type.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| View-model (search + sort) | `lib/features/meds/presentation/view_models/meds_list_view_model.dart` | Replace substring filter with fuzzy scorer; attach/compute match score; order by score while query active, name otherwise; expose query-active to the screen |
| Fuzzy matcher (likely new) | `lib/features/meds/presentation/.../fuzzy_name_match.dart` **(new)** or `lib/core/utils/` | Pure typo-tolerant scorer (Levenshtein/normalized similarity). HOW (package vs pure-Dart) decided in `/plan` |
| Screen (search UI + empty gating) | `lib/features/meds/presentation/screens/meds_screen.dart` | Rebuild search affordance as animated slide-in bar (icon + field + inline ×, `surfaceContainer`, title fade, deferred focus); pass `queryActive` to sections; keep global zero-meds card |
| Section widget | `lib/features/meds/presentation/widgets/medication_section.dart` | Gate per-section placeholder on `queryActive && items.isEmpty`; always render header |
| Tile widget | `lib/features/meds/presentation/widgets/medication_tile.dart` | Completed-state de-emphasis (opacity + neutral badge + grey status chip); course chip order (type before status) |
| Dependencies (conditional) | `pubspec.yaml` | Add a vetted fuzzy package **only if** `/plan` selects one over pure-Dart (§2.3 allowlist + justification) |
| l10n | `lib/l10n/app_{en,de,uk}.arb` | **Likely no new keys** — reuse `medsListSectionEmpty`, `medsListEmpty*`, `medsListSearchHint`. (Confirm during `/plan`; add only if a new string emerges.) |
| Tests | `test/features/meds/...` | Fuzzy/ranking view-model unit tests; update/extend screen widget tests (search animation states, empty-state gating, completed-tile styling, chip order) |

## 5. Acceptance Criteria

**Search bar (animated slide-in)**
- [x] **AC-1**: Activating search expands an animated bar (slide-in from the trailing edge, ~220 ms) over the app-bar region; the title fades out during the transition and is restored on close.
- [x] **AC-2**: The expanded bar shows a leading search icon, the text input (hint `medsListSearchHint`), and a trailing clear (×) **inside the bar**; the bar background uses the `surfaceContainer` token. The × is not placed in the app-bar `actions`.
- [x] **AC-3**: Input focus is requested after the open animation completes (not synchronously on the first frame).
- [x] **AC-4**: Closing search (trailing ×) collapses the bar with the reverse animation, clears the query, and restores the title; the list returns to its filter-respecting unsearched state. Search toggle and clear targets are ≥ 48 dp.

**Fuzzy matching & ranking (pure view model)**
- [x] **AC-5**: Name matching is typo-tolerant (Levenshtein/normalized similarity), case-insensitive, over `Medication.name`, computed in-memory in the pure view model — no DB query and no schema change.
- [x] **AC-6**: Any medication whose name contains the query as a case-insensitive substring is always included (no regression vs the prior substring behaviour); additionally, close fuzzy matches at/above a tuned threshold are included (e.g. "omeprzol" → "Omeprazol", "magnij b6" → "Magniy B6"); clearly unrelated names are excluded.
- [x] **AC-7**: A blank/whitespace-only query disables matching (full filter-respecting list); fuzzy results still respect the active All/Active filter (search applied before filter).
- [x] **AC-8**: While a query is active, items within each section are ordered by descending match score with ties broken by case-insensitive name ascending; with no active query, items are ordered case-insensitive name ascending.
- [x] **AC-9**: The matcher/scorer is a pure function (no Flutter/drift/`DateTime.now()`) and is unit-tested with fixed inputs covering: exact substring, single-character typo, transposition, prefix, and below-threshold non-match.

**Empty / "nothing found" states**
- [x] **AC-10**: With zero medications in the database (`totalCount == 0`), the global centered empty card (`medsListEmptyTitle` + `medsListEmptyBody`) is shown and takes precedence over the sections.
- [x] **AC-11**: The per-section "Нічого не знайдено" placeholder (`medsListSectionEmpty`) renders **only** when a search query is active and that section has zero matches; with no active query an empty section shows its header with no placeholder.
- [x] **AC-12**: When an active query matches nothing in either section, both section headers render, each with its own per-section placeholder beneath it (no single consolidated message).
- [x] **AC-13**: Loading and error states remain handled (all three `AsyncValue.when` branches), unchanged from spec 034.

**Completed-tile de-emphasis & chip order**
- [x] **AC-14**: A tile whose derived activity is `Completed` is dimmed to ≈ 0.65 opacity, uses a neutral icon badge (`surfaceVariant`/`onSurfaceVariant`), and a grey status chip (`surfaceVariant`/`onSurfaceVariant`); active tiles are visually unchanged.
- [x] **AC-15**: Course tiles render the type chip (Day X/Y or Paused) before the status chip; continuous tiles render status before type — matching the design's documented per-type order.

**Quality**
- [x] **AC-16**: `dart analyze` is clean (no new warnings); no debug artifacts (`print`/`debugPrint`) introduced; any added package clears the §2.3 allowlist with justification, or a pure-Dart matcher is used with no new dependency.
- [x] **AC-17**: The existing add-medication golden integration flow still passes (a newly added medication appears in the list with no manual refresh), and the meds-list widget/test suite is updated to cover the new search/empty/tile behaviour and passes.

## 6. Out of Scope

- NOT included: **Archive** state, the `Архів` filter chip, archived-tile styling, and the chip-row scroll-vs-wrap change (only relevant once a 3rd chip exists) — deferred follow-up (needs `archivedAt`/`isArchived` column → schema bump + migration). Note: "Completed" (this spec) is a **derived** state and is distinct from a stored "Archived" state.
- NOT included: **DB-level / FTS5 search** — matching stays in-memory (SQLite has no typo-fuzzy; dataset is tiny). No drift schema or query change.
- NOT included: Medication **detail / edit / delete** screens or tile-tap navigation (the chevron stays decorative; no `InkWell`/hover ripple this slice).
- NOT included: Searching across fields **other than name** (form, notes, dose) or search history/suggestions.
- NOT included: Cosmetic micro-token polish surfaced by the audit but unrelated to the named goals — filter-chip unselected label colour, exact `.f-chip` padding, and `.sec-head` letter-spacing. (Can be a later design-polish pass.)
- NOT included: Changing the reactive read path, repository contract, data source, or mappers (they already provide the live list).
- NOT included: Non-daily **frequency** UI, intake/"today" status on tiles, stock editing.

## 7. Technical Constraints

- **Clean Architecture (§2.1)**: fuzzy matching/sorting lives in the **presentation view model** (or a pure helper consumed by it), never in `domain/` and never as a DB query. Screens/widgets consume only domain-typed providers; the composition seam stays as-is.
- **Domain purity (§2.1)**: the scorer must be pure Dart (no Flutter/drift imports, no `DateTime.now()`); place it in `presentation/` or `core/utils/`, not `domain/`.
- **Either at boundaries (§3.2)**: unchanged — the reactive read still returns `Stream<Either<Failure, List<Medication>>>` folded to `AsyncValue`; this spec touches only post-load shaping and rendering.
- **No schema change (§6.5)**: must not bump `schemaVersion` or alter any column.
- **Packages (§2.3)**: if a fuzzy package is added, it must be added via `flutter pub add`, clear the allowlist (pub score ≥ 70, maintained < 12 mo, no telemetry/ads, permissive licence), and be justified; a pure-Dart Levenshtein implementation is an acceptable no-dependency alternative.
- **Clock (§4.2.1)**: activity/`CourseProgress` derivation stays Clock-injected and unchanged; the search/sort layer is time-independent.
- **Material 3 (§4.3.1)**: search bar, chips, and tiles use M3 widgets/theme tokens (no hardcoded colours); interactive targets ≥ 48 dp; the search animation uses standard Flutter transitions.
- **l10n**: reuse existing keys where possible; any new string is added to all three `.arb` files and regenerated via `flutter gen-l10n`; widget tests assert localized output.
- **Testing (§3.4)**: fuzzy/ranking unit tests are mandatory; screen states (search animation, empty gating, completed-tile styling, chip order) covered by widget tests with overridden providers; the spec-033 add-medication golden flow must stay green.
- **Minimal changes (§6.1)**: behaviour-preserving for everything except the explicitly changed search semantics, empty-state gating, and completed-tile styling — do not refactor unrelated tile/section code.

## 8. Open Questions

- **OQ-1 (resolved)**: Fuzzy flavour = **Levenshtein / typo-tolerant** (user decision, 2026-06-18). Package-vs-pure-Dart is a `/plan` decision.
- **OQ-2**: Exact fuzzy **similarity threshold** and score normalization (what counts as "close enough") — to be tuned in `/plan`/implementation against the seed set so unrelated names don't leak in while one- to two-character typos still match.
- **OQ-3**: Whether the score-ranked order should be **global across both sections** or strictly **within each section** — this spec assumes **within each section** (sections are preserved); revisit only if grouping is later dropped.
- **OQ-4**: Whether to extract the matcher to `core/utils/` (reusable for future searchable lists, e.g. history) vs keep it feature-local in `meds/presentation/` — a `/plan` structuring detail; either satisfies the purity constraint.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Fuzzy threshold too loose (unrelated meds appear) or too tight (typos miss) | Med | Med | Tune against the seed set; unit-test boundary cases (AC-9); guarantee substring always matches (AC-6) |
| Animated search-bar rebuild breaks existing meds-list widget tests (which assert the title-swap shape) | High | Low | Expected — update those tests as part of this slice (AC-17); keep semantic keys stable for finders |
| Score-ranked ordering conflicts with the alphabetical assumption baked into existing tests | Med | Low | Condition the sort on query-active; assert both orderings explicitly in tests |
| Added fuzzy package fails §2.3 allowlist or bloats the local-only app | Low | Med | Prefer a small/pure-Dart implementation; vet score/licence in `/plan`; pure-Dart Levenshtein is the fallback (no dependency) |
| Completed-tile restyle accidentally changes active-tile appearance | Low | Med | Gate every override on `activity == completed`; widget-test an active vs completed tile side-by-side |
| Slide-in animation jank or focus race (keyboard appears before bar settles) | Med | Low | Defer focus to post-animation (AC-3); use standard `SlideTransition`/`AnimatedSwitcher`; test pump-and-settle |
| Search bar over the AppBar interferes with the routing shell / bottom-nav | Low | Med | Keep search within the screen's own AppBar/flexibleSpace; verify on-device against the `StatefulShellRoute` |
