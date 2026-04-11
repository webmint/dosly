# Review Report: 001-m3-theme

**Date**: 2026-04-11
**Spec**: `specs/001-m3-theme/spec.md`
**Plan**: `specs/001-m3-theme/plan.md`
**Changed files**: 13 source/test files + 7 asset files (pubspec.yaml + 4 Roboto TTFs + LICENSE.txt + SOURCE.md)

All 8 tasks: **Complete**. Review agents ran on the final committed state.

---

## Security Review

**Summary**: Critical: 0 | High: 0 | Medium: 0 | Info: 13
**Verdict**: **PASS**

This is a UI theme scaffolding spec. It has zero network I/O, zero persistent storage, zero user input beyond a theme-cycle button, zero auth code, zero PHI handling, and zero third-party packages added (only font asset declarations). Many OWASP MASVS categories do not apply.

### Findings

#### Critical (exploit risk)
None.

#### High (security weakness)
None.

#### Medium (defense-in-depth gap)
None.

#### Info (hardening suggestions and positive observations)
- **`assets/fonts/SOURCE.md`** — Supply-chain integrity is strong. SHA-256 hashes for all four Roboto TTFs are recorded in `SOURCE.md` and independently verified against the on-disk binaries. **Recommendation**: consider adding a CI check that re-verifies hashes on every build to catch silent corruption or substitution.
- **`assets/fonts/LICENSE.txt`** — Correctly ships SIL OFL 1.1 (matches Roboto v3 actual license), not Apache 2.0.
- **`lib/app.dart:26`** — `debugShowCheckedModeBanner: false` is a UX flag, not a debug-build toggle. Does not disable assertions, DevTools, or any security control. Benign.
- **`pubspec.yaml`** — Zero new package dependencies added. Only font asset declarations + description update. No supply-chain exposure.
- **`lib/core/theme/theme_controller.dart`** — In-memory singleton with no persistence, no I/O, no cross-isolate access. Cannot leak or be exploited.
- **Constitution §4.2.1 (no medication/dosage/intake logging)** — Trivially satisfied; zero `print`, `debugPrint`, `developer.log`, or custom logger calls in any changed `lib/` file.
- **Constitution §4.2.1 (no cloud sync without opt-in)** — Trivially satisfied; no network code, no persistence, no platform channels.
- **Constitution §2.3 (dependency rules)** — Satisfied; no packages added, only font asset declarations (the correct mechanism).
- **No `!` null assertions, no unchecked `as` casts, no `dynamic` types, no `dart:mirrors`, no `Process.run`, no `jsonDecode`, no WebView, no deep-link handlers, no untrusted file-path construction** anywhere in changed files.

---

## Performance Review

**Summary**: High: 0 | Medium: 0 | Low: 0 (no bottlenecks)
**Verdict**: **PASS** (with 2 optional polish observations)

### Metrics

| Metric | Value | Target | Status |
|---|---|---|---|
| App size added (fonts) | ~1.4 MB uncompressed / ~500–700 KB compressed | — | Proportional |
| Startup path | synchronous (no async I/O in `main()`) | synchronous | ✅ |
| First-frame cost | two `const ColorScheme` literals + one `const TextTheme` + one `_build()` constructing 11 sub-themes | < 16.67 ms | ✅ (microseconds) |
| Rebuild scope on theme change | whole `MaterialApp` (one rebuild per `themeController.cycle()`) | infrequent | ✅ |

### Bottlenecks Found
None — this is a scaffolding spec with a simple preview screen.

### Observations (optional polish, not blockers)

1. **Roboto Light (300) and Bold (700) weights are unreferenced by the type scale.** [Low priority]
   The M3 type scale in `app_text_theme.dart` uses only `w400` (body/display/headline) and `w500` (title/label). Dropping Light + Bold would save ~700 KB uncompressed (~250–350 KB compressed).
   **Recommendation**: keep them as future-proofing for emphasis/ad-hoc overrides, or drop them to trim app size. Intentional decision — flag for the team.

2. **`AppTheme.lightTheme` / `darkTheme` are getters, not memoized.** [Low priority]
   Both getters call `_build()` on every access. `DoslyApp` passes them to `MaterialApp` on every `ListenableBuilder` fire, constructing two fresh `ThemeData` objects per theme cycle. In profile/release this is microseconds — not a real bottleneck. Optional memoization:
   ```dart
   static final ThemeData lightTheme = _build(lightColorScheme);
   static final ThemeData darkTheme = _build(darkColorScheme);
   ```
   One-line change, zero readability cost, eliminates redundant `ThemeData` construction.

3. **Startup path is clean.** `main()` runs `runApp(const DoslyApp())` with no async setup, no `WidgetsFlutterBinding.ensureInitialized()`, no platform channels. Bundled Roboto means no FOUC or runtime font fetch (vs `google_fonts`).

4. **`const` discipline is strong.** All widgets that can be `const` are. `AppTextTheme.textTheme` is `static const`. Icons are built-in `MaterialIcons` font — zero asset cost.

5. **Layout is correct for the preview screen's data size.** `SingleChildScrollView` + `Wrap` (not `GridView`) for 28 swatches is the right call. No nested scrollables.

6. **`_iconForMode` correctness note** (out of perf scope, surfaced for awareness): The `IconButton`'s icon in the app bar reads `themeController.value` directly, not through a `ListenableBuilder` inside the screen. It refreshes only because the ancestor `DoslyApp`'s `ListenableBuilder` rebuilds the whole tree. Works correctly in this spec, but note for future when screens may need finer-grained rebuilds.

---

## Test Assessment

**Summary**: 4 fully COVERED + 3 PARTIAL + 1 NOT COVERED of 9 automation-eligible ACs; 6 ACs are N/A for automated testing (static/manual).
**Verdict**: **GAPS FOUND**

79/79 tests pass. The color-scheme and theme-controller test suites are exhaustive. The real gap is that `AppTheme.lightTheme` / `darkTheme` have **zero automated assertions** — a regression dropping `useMaterial3`, wiring the wrong `colorScheme`, or losing the Roboto family would not fail any test.

### AC Coverage Matrix

| AC | Status | Covering test(s) or reason |
|---|---|---|
| AC-1 (const literals, no fromSeed) | PARTIAL | `app_color_schemes_test.dart` verifies brightness + 35 hex values per scheme. Does NOT assert `const` or the absence of `fromSeed` (static-verification AC). |
| AC-2 (light spot-checks) | COVERED | 35 light-scheme assertions. |
| AC-3 (dark spot-checks) | COVERED | 35 dark-scheme assertions. |
| AC-4 (AppTheme shape) | **NOT COVERED** | No test imports `app_theme.dart`. No assertions on `useMaterial3`, `colorScheme` binding, or Roboto-based `textTheme`. |
| AC-5 (pubspec fonts + .ttf files) | N/A | Asset/pubspec — static inspection. |
| AC-6 (ThemeController API) | COVERED | 7 unit tests cover default, setMode, notify, full cycle. Minor nit: top-level `themeController` singleton's initial state is not asserted. |
| AC-7 (DoslyApp wiring) | PARTIAL | Widget smoke test pumps `DoslyApp` and verifies the preview renders. Not asserted: `title: 'dosly'`, `debugShowCheckedModeBanner: false`, explicit identity of `theme`/`darkTheme` to `AppTheme` getters, `home` is `ThemePreviewScreen`. |
| AC-8 (main.dart line count) | N/A | Static inspection. |
| AC-9 (preview screen content) | PARTIAL | Verifies app-bar title + cycle tooltip/button. NOT asserted: presence of the 28 `ColorSwatchCard`s, 15 `TypographySample`s, or the individual components (`FilledButton`, `Chip`, `Card`, `TextField`, `FAB`, `Switch`). |
| AC-10 (rounded icons) | N/A | Static grep check. |
| AC-11 (dart analyze) | N/A | Not a unit test. |
| AC-12 (flutter test passes) | COVERED | 79/79 passing. |
| AC-13 (manual iOS + Android run) | N/A | Deferred to user per spec. |
| AC-14 (no Color(0xFF) outside core/theme) | N/A | Static grep check. |
| AC-15 (no Flutter in domain) | N/A | Trivially true — no `domain/` layer yet. |

### Coverage Summary
- Automation-eligible ACs: 9 (AC-1, AC-2, AC-3, AC-4, AC-6, AC-7, AC-9, AC-10 via grep, AC-12)
- Fully covered: 4 (AC-2, AC-3, AC-6, AC-12)
- Partial: 3 (AC-1, AC-7, AC-9)
- Not covered: 1 (**AC-4**)
- N/A for automation: 6

### Gaps Remaining

1. **[Medium] AC-4 has zero automated assertions** — `app_theme.dart` has no dedicated test. A regression where `useMaterial3` is dropped, `colorScheme` is wired to the wrong brightness, or `textTheme` loses its Roboto family would not fail any test. Fix: add ~15 lines to a new `test/core/theme/app_theme_test.dart`:
   ```dart
   expect(AppTheme.lightTheme.useMaterial3, isTrue);
   expect(AppTheme.lightTheme.colorScheme, lightColorScheme);
   expect(AppTheme.lightTheme.textTheme.bodyLarge?.fontFamily, 'Roboto');
   // same for darkTheme
   ```

2. **[Low–Medium] AC-9 structural component presence is not asserted** — `ThemePreviewScreen` is the single user-facing artifact of this spec. A refactor that accidentally deletes the typography section, a swatch card, or the `TextField` would ship silently. Fix: add `find.byType(FilledButton)`, `find.byType(Chip)`, `find.byType(ColorSwatchCard)`, etc. assertions to `widget_test.dart`.

3. **[Low] AC-7 exact wiring not asserted** — `MaterialApp.title`, `debugShowCheckedModeBanner`, explicit `theme` identity. Fix: extract `MaterialApp` via `tester.widget<MaterialApp>(find.byType(MaterialApp))` and assert those fields (~10 lines).

### Positive observations
- The color-scheme test file (70 per-field hex assertions) is exhaustive and matches the spec §9 drift-protection intent.
- The `ThemeController` test file is thorough on the state machine.
- Widget smoke test is minimal but correct, and resets the singleton in `setUp` to prevent inter-test state leakage.
- `ColorSwatchCard` and `TypographySample` correctly have no dedicated tests (they're private-feeling preview widgets — demanding tests would be over-engineering for this spec's scope).

---

## Overall Review Verdict

| Dimension | Result |
|---|---|
| Security | **PASS** — zero findings |
| Performance | **PASS** — no bottlenecks; 2 optional polish items |
| Test coverage | **GAPS FOUND** — one real gap (AC-4) + two minor partials |

This review report does not render a final verdict — that is `/verify`'s job. The review findings will be incorporated into `/verify`'s verdict against the 15 acceptance criteria.

**Recommendation to `/verify`**: the test gaps are real but narrow (~25 lines of test code to close completely). The security and performance posture is clean. `/verify` should decide whether to:
- **Block** pending a follow-up task to add the missing tests
- **Approve with a tech-debt item** to add the missing tests in a later spec
- **Approve as-is** if manual run (AC-13) confirms visual correctness

The optional performance polish (trim unused Roboto weights, memoize `AppTheme` getters) is not blocking and belongs in a separate polish task if at all.
