# Research: Medications List — Search Behaviour, DB-Wired Fuzzy Search & Empty States

**Date**: 2026-06-18
**Topic**: Fix the meds-list screen's design/behaviour mismatch vs the template, wire name-search to the DB with fuzzy matching that narrows live, and show a "nothing found" message when the (filtered/searched) list is empty.
**Verdict**: **Feasible** — mostly design-fidelity polish + a small in-memory fuzzy upgrade.

> **Decision baked in (user, 2026-06-18)**: fuzzy matching = **Levenshtein / typo-tolerant** (OQ-1 → Option A2). Expect to add one vetted fuzzy package (constitution §2.3 allowlist: pub score ≥70, maintained, no telemetry, permissive licence). Examples to evaluate: `fuzzywuzzy`, `string_similarity`, `fuzzy`.

## Summary

The big surprise: **the list is already wired to the database reactively, and search already narrows the list live as you type.** `medicationsListProvider` watches a drift join (`watchAllMedications()`) that re-emits on any med/slot change, and `buildMedsListView` filters that list by a case-insensitive **substring** match on each keystroke. So "wire to DB" and "list narrows" are *done*. What's actually missing is three things: (1) the search **UI/behaviour doesn't match the template's animated slide-in search bar**; (2) matching is **substring, not fuzzy** (no typo tolerance, no ranking); (3) the **empty / "nothing found" logic diverges** from the design (it shows per-section placeholders even when you're not searching, and completed meds aren't visually de-emphasised). All three are presentation-layer changes plus one pure view-model change — no schema migration, no new architecture.

## Codebase Findings

### Existing Related Code
| Area | Files | Relevance |
|------|-------|-----------|
| Screen + search UI + empty state | `lib/features/meds/presentation/screens/meds_screen.dart` | App-bar title↔TextField swap, two filter chips, global `_EmptyState`, sections |
| Search/filter/sort logic | `lib/features/meds/presentation/view_models/meds_list_view_model.dart:130` | `query.toLowerCase().contains(...)` — the substring matcher to upgrade to fuzzy |
| Section + per-section empty | `lib/features/meds/presentation/widgets/medication_section.dart:50` | Renders `medsListSectionEmpty` whenever `items.isEmpty` (even with no active search) |
| Tile rendering | `lib/features/meds/presentation/widgets/medication_tile.dart` | Badge variant, chips, no completed-state dimming |
| Reactive DB read (already wired) | `lib/features/meds/data/datasources/medication_local_data_source.dart:57` (`watchAllMedications`) → `medication_providers.dart:65` (`medicationsList` stream) | Confirms the list is already DB-backed and live |
| l10n | `lib/l10n/app_{en,de,uk}.arb` | `medsListSectionEmpty` ("Нічого не знайдено") already exists; no distinct "no search results" key |

### Patterns Available
- **Pure, Clock-injected view model** (`buildMedsListView`) — the natural, testable home for a fuzzy matcher (stays Flutter/drift-free, unit-tested without pumping widgets).
- **Reactive `Stream<Either>` → `AsyncValue`** read pattern is already canonical (MEMORY 2026-06-18) — no change needed for search; filter in-memory over the already-loaded list.
- **`MedicationActivityStatus.active/completed`** is already derived per item — everything needed to dim/restyle completed tiles already exists in `MedListItem`.

### Gaps
- No fuzzy/ranking utility anywhere (`pubspec` has no fuzzy/search package).
- No animated search-bar widget; no `surfaceContainer` search overlay.
- No completed-state tile treatment (opacity / neutral badge / grey status token).
- No flag distinguishing "section empty because you searched" from "section empty because there are none of this type".

## Design Audit (design-auditor agent) — Mismatches

Severity-ordered. Every finding is grounded in template selectors/lines and `file:line` code evidence.

| # | Area | Severity | Design specifies | Code does | Fix direction |
|---|------|----------|------------------|-----------|---------------|
| 1 | Search affordance | **High** | `appbar-search-wrap` overlay slides in from right (`translateX(100%)→0`, `.22s ease`), bg `surface-container`; search icon left → input → **clear-× inline right**; title/button fade to opacity 0 (template ~1170–1184, 1843–1847) | Raw title→`TextField` swap, no overlay/animation/bg change; × in AppBar `actions` (`meds_screen.dart:99–134`) | `Stack` in `flexibleSpace` + `SlideTransition`; `surfaceContainer` bg; × as input suffix; `AnimatedOpacity` title |
| 2 | Search animation/focus | **High** | Slide `.22s`; focus deferred `setTimeout(...,230)` (template 2922) | Synchronous swap; `autofocus: true` fires immediately (`meds_screen.dart:105`) | `SlideTransition` 220ms ease-out; focus after animation |
| 3 | Search toggle / × placement | Med | Search button fades (not removed); × lives inside the overlay (template 1846) | Search button removed and replaced by × in `actions` (`meds_screen.dart:123–134`) | Move × inside the search field; fade the toggle |
| 8 | Empty state | **High** | Per-section "Нічого не знайдено" visible **only while query active** (`q.length>0 && !hasVisible`, template 2976); NO global empty card | Per-section placeholder shows whenever `items.isEmpty` even at rest (`medication_section.dart:50`); global `_EmptyState` for `totalCount==0` (`meds_screen.dart:173`) | Gate per-section placeholder on `queryActive`; global card for "zero meds ever" is acceptable |
| 9 | Completed/archived tile opacity | Med | `opacity:.65/.5` on de-emphasised tiles (template 1916–1946) | Full opacity always (`medication_tile.dart`) | `Opacity(opacity: completed ? .65 : 1, …)` |
| 10 | Completed badge variant | Med | `.med-iconify.neutral` → `surface-variant` (template) | Badge colour by type only (`medication_tile.dart:49–52`) | Override to `surfaceVariant`/`onSurfaceVariant` when completed |
| 11 | Completed status chip token | Med | `.s-chip.grey` → `surface-variant` | Uses `surfaceContainerHighest` (`medication_tile.dart:212`) | Use `surfaceVariant` |
| 13 | Chip order (course tiles) | Med | `День 7/30` then `Активний` (template 1901,1911) | Status then type — reversed (`medication_tile.dart:119–121`) | Render type before status for courses |
| 5 | Filter-chip unselected colour | Low | `.f-chip` label `on-surface-variant` (template 709) | `onSecondaryContainer` (`meds_screen.dart:269`) | Use `onSurfaceVariant` |
| 6/7 | Chip padding / row scroll | Low | `.f-chip` padding `6px 16px`; `.chip-row` horizontal scroll, hidden scrollbar | `Wrap(spacing:8)` + `FilterChip` labelPadding (`meds_screen.dart:227–279`) | `SingleChildScrollView(horizontal)` + Row; `RawChip` with exact padding |
| 16 | Section-header letter-spacing | Low | `.sec-head { letter-spacing:.1px }` (template 729) | Not set (`medication_section.dart:114`) | Add `letterSpacing: .1` |

(Items 4, 12, 14, 15, 17 audited and found acceptable / behaviour-matching.)

**Auditor verdict**: low fidelity on the interaction layer (search), moderate on the static tile layer; completed-course tiles are currently indistinguishable from active ones; tile typography/spacing/icon sizes are largely correct.

## Constitution Constraints

| Rule | Impact |
|------|--------|
| §2.1 domain purity / presentation may not import `data/` | Fuzzy matching belongs in the **pure view model** (`presentation/`), not domain, not a DB query |
| §2.3 adding packages (`flutter pub add`, score ≥70, maintained, no telemetry) | The chosen Levenshtein package must clear the allowlist; justify in spec/PR |
| §3.7 / "search before building" | Confirm no existing fuzzy util before adding the package (none found) |
| §3.4 testing | View-model fuzzy/ranking is mandatory unit-test territory; screen states get widget tests |
| §6.5 no schema change | Fuzzy search stays in-memory; no drift/FTS change (SQLite has no typo-fuzzy anyway) |
| §4.3.1 M3 / 48dp tap targets | Animated search bar + chips must keep ≥48dp targets |

## Approaches

### Search engine ("fuzzy by name") — **Option A2 chosen: in-memory Levenshtein, ranked**
- Replace `buildMedsListView`'s `.contains()` with a typo-tolerant scorer (edit-distance / token ratio) from a vetted package; when a query is active, **sort by score** instead of alphabetically.
- Pros: stays in the pure, already-tested view model; no schema/architecture change; tiny dataset → instant; fully unit-testable with fixed inputs; tolerates typos ("omeprzol"→"Omeprazol", "magnij b6"→"Magniy B6").
- Cons: adds one dependency (vet per §2.3); must tune a score threshold + the score-vs-alphabetical sort switch.
- Complexity: **Low**.

**Rejected — Option B: DB-level (`LIKE`/FTS5).** `LIKE '%q%'` is substring (no improvement); FTS5 is token/prefix, **not typo-fuzzy**, and would need a schema/virtual-table change (§6.5) for a handful of rows. Med–High complexity for zero benefit.

### Search UI + empty states — single approach
Rebuild the app-bar search as an animated slide-in overlay (`Stack` in `flexibleSpace` + `SlideTransition`/`AnimatedSwitcher`, `surfaceContainer` bg, inline clear-×, deferred focus); gate the per-section "nothing found" on `queryActive`; add completed-tile treatment (opacity + neutral badge + grey chip) and fix course chip order. All presentation-layer. Complexity: **Med** (fiddly but mechanical).

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | **Med** | ~5–7 files: `meds_screen.dart`, `medication_section.dart`, `medication_tile.dart`, `meds_list_view_model.dart`, new fuzzy helper/wrapper, l10n (×3), tests |
| New dependencies | **Low** | One vetted Levenshtein/fuzzy package (§2.3) |
| Risk | **Low–Med** | Behaviour-preserving except search semantics; main risks are the score-vs-alphabetical sort switch, package vetting, and not regressing the 481-test suite / golden integration flow |

## Recommendation

**Proceed to `/specify`.** A coherent single-feature slice (search + empty-state fidelity), not a localized bug, touching enough files that the spec→plan→breakdown gates earn their keep. Suggested kickoff:

> `/specify "Rework the meds-list search to match the template's animated slide-in search bar, upgrade name matching from substring to typo-tolerant (Levenshtein) ranked fuzzy matching done in-memory over the existing reactive list (results ranked by match score), and align empty/'nothing found' states with the design (per-section placeholder only while searching; de-emphasised completed-course tiles: opacity + neutral badge + grey status chip). Presentation + view-model only; no schema change."`

### Open questions for `/specify`
- **OQ-1 — fuzzy flavour**: **RESOLVED → Levenshtein / typo-tolerant (vetted package).**
- **OQ-2 — empty-state UX on a global no-match**: when a search matches nothing across both sections, show two per-section "nothing found" placeholders (template-faithful) or one consolidated message? May need a new l10n key distinct from `medsListSectionEmpty`.
- **OQ-3 — sort during search**: switch to score-ranked ordering while a query is active, back to alphabetical when cleared? (Recommended: yes.)
- **OQ-4 — completed-tile styling scope**: the missing dimming/neutral-badge/grey-chip is for **completed** (already-derived) courses — in scope here. Distinct from the deferred **Archive** state (needs the schema migration). Confirm completed-tile styling lands in this slice.

### Notable references
- Design source of truth: `dosly_m3_template.html` `#s-meds` (markup ~1838–1982; search CSS ~1170–1207; chips ~702–720; JS `toggleSearch`/`clearSearch`/`filterMeds` ~2915–2985).
- Prior feature: `specs/034-meds-list/spec.md` (Complete) — established the reactive read, the list, and deferred Archive.
- MEMORY (2026-06-18): reactive `Stream<Either>`→`AsyncValue` read pattern; DST calendar-day counting fix; drift `.watch()` test pattern (`closeStreamsSynchronously: true`).
