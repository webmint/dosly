# Review Report: 019-router-error-screen

**Date**: 2026-05-18
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)
**Changed files**: 11 (1 source, 1 test, 3 ARB, 4 auto-regenerated l10n, 1 bug record, 1 architecture doc)

All 3 tasks Complete. Review covers the full feature diff against `main`.

---

## Security Review

**Verdict**: PASS

- **Critical**: 0 | **High**: 0 | **Medium**: 0 | **Info**: 8

The implementation correctly avoids the two non-trivial pitfalls in error-screen design: (a) reflecting attacker-controlled `state.uri` into the UI, and (b) deriving the recovery target from user input. The deferred `redirect:` allow-list is acceptable today because external deep-link ingress is platform-disabled (verified `AndroidManifest.xml` has only the LAUNCHER intent-filter; no iOS `CFBundleURLTypes` exists), but it MUST be added in the same PR that enables any `VIEW` intent-filter or `CFBundleURLTypes` entry.

### Findings

#### Critical
None.

#### High
None.

#### Medium
None.

#### Info (hardening observations + forward-looking guidance)

- **`lib/core/routing/app_router.dart:94-123` — Deep-link parameter validation OK**. `_RouterErrorScreen` takes no `GoRouterState state` parameter and reads zero attacker-controlled fields. All three rendered strings come from `context.l10n.errorScreen*` (compile-time ARB constants). Spec §6 decision honored.
- **`lib/core/routing/app_router.dart:94-123` — Information disclosure OK (CWE-209 / CWE-200 not applicable)**. No stack-trace, exception message, route name, or path is rendered. A reconnaissance attempt against `/admin`, `/internal/debug`, etc. yields the identical generic screen — zero application-surface mapping.
- **`lib/core/routing/app_router.dart:115` — `context.go('/')` recovery target safe**. `/` is a hard-coded literal, not derived from `state.uri`. No auth-bypass primitive introduced (no auth gating exists in the app per constitution §1; when future auth/onboarding gating is added via `redirect:`, it will run for `context.go('/')` exactly as for any other navigation).
- **`lib/l10n/app_en.arb` / `app_de.arb` / `app_uk.arb` — Sensitive Data Exposure OK**. All 9 new string values contain only generic user-facing copy. No secrets, internal endpoints, version strings, debug hints, or PII.
- **Allow-list redirect deferral acceptable today** (verified `android/app/src/main/AndroidManifest.xml` has only LAUNCHER intent-filter; no `android.intent.action.VIEW` with `android:scheme`/`android:host`; no iOS `CFBundleURLTypes`). External deep-link ingress is currently impossible at the platform layer. **Required follow-up**: When constitution §5.2 notification-action deep links are wired (or any `<intent-filter android:scheme="...">` / `CFBundleURLTypes` is added), the same PR MUST introduce a `GoRouter.redirect:` allow-list and reject unknown schemes/hosts/paths before `errorBuilder` is reached.
- **`test/core/routing/app_router_test.dart` Test 7 — Test surface clean**. Hard-coded `/nonexistent` and English copy values are already in the source ARB and ship in every release. Tests are not bundled into release artifacts. No new attacker-useful information exposed.
- **`pubspec.yaml` / `pubspec.lock` — Dependency surface unchanged**. `git diff main -- pubspec.yaml pubspec.lock` returns empty. Zero new dependencies introduced. No new transitive supply-chain surface.
- **`lib/core/routing/app_router.dart:103` `automaticallyImplyLeading: false` — Hardening, not regression**. System back gesture / hardware back button still pops the route; the explicit `FilledButton` is the affordance. Removing the leading arrow REDUCES risk in the future deep-link scenario — landing on `/typo` via external URI has no stale stack to "back" into; a back arrow would be misleading.

---

## Performance Review

**Verdict**: CLEAN

- **High**: 0 | **Medium**: 0 | **Low**: 0

All 8 performance dimensions evaluated favorably. The implementation is `const`-maximal for a runtime-string widget, performs exactly **1** InheritedWidget lookup per build (the `context.l10n` extension reads once into a local), adds zero cost to the startup path (function-pointer field assignment only), renders in a single synchronous frame with no async operations, and has negligible app size impact (~200 bytes of ARB strings + a few hundred bytes of generated Dart after tree-shaking).

### Metrics

| Metric | Value | Target |
|---|---|---|
| Cold-path allocation | 0 objects at boot (`const _RouterErrorScreen()` is compile-time-canonicalized) | N/A |
| `const` widget nodes | `EdgeInsets.all(24)`, `SizedBox(height: 16)` — both `const` | Maximal for runtime-bound tree |
| InheritedWidget lookups per build | 1 (`AppLocalizations.of(context)` via `Localizations.of`) | 1 |
| ARB payload | ~9 short strings + 4 regenerated getters | Negligible |
| Frames to first paint | 1 (synchronous build, no async ops) | 1 |
| Startup overhead | 0 (function pointer stored, not called) | 0 |
| Test 7 wall-clock | 5-20 ms on modern CI | within variance |

### Findings

None. No finding rises above the negligible threshold.

---

## Test Assessment

**Verdict**: GAPS FOUND (1 material AC-coverage gap; 5 optional improvements)

### AC Coverage

| AC | How verified | Coverage |
|---|---|---|
| AC-1 | grep `errorBuilder:` (1) + indirectly by Test 7 (without it, `/nonexistent` would not render the error screen and `find.text('Page not found')` would fail) | ✓ Covered |
| AC-2 | Source review: `_RouterErrorScreen.build()` constructs Scaffold + AppBar + Text(body) + FilledButton. Test 7 asserts title and button surface strings. **Body text is not directly asserted.** | ⚠ Partial — see Gap 1 |
| AC-3 | Test 7 pushes `/nonexistent`, asserts `'Page not found'` `findsOneWidget`, asserts `'Go to home'` button present, taps, asserts `HomeScreen` `findsOneWidget`. All three spec-mandated assertions present. | ✓ Covered |
| AC-4 / AC-5 / AC-6 | Grep on all 3 ARBs confirms keys + values. Gen-l10n gate (AC-7) enforces presence. | ✓ Covered (build gate) |
| AC-7 | All 4 generated files contain the new getters. `grep -l "errorScreenTitle" lib/l10n/app_localizations*.dart \| wc -l` = 4. | ✓ Covered (build gate) |
| AC-8 | Test 7 asserts `find.byType(AppBottomNav)` is `findsNothing` while error screen is showing, `findsOneWidget` after recovery. | ✓ Covered |
| AC-9 | `grep -nE '![.$]' lib/core/routing/app_router.dart` → no matches. | ✓ Covered (static grep) |
| AC-10 | `git diff main -- lib/core/routing/app_router.dart \| grep "^+import '\.\./\.\./features/"` → 0 matches. | ✓ Covered (static grep) |
| AC-11 | `dart analyze` exit 0 (PostToolUse hook + explicit run). | ✓ Covered (analyze gate) |
| AC-12 | `flutter test test/core/routing/app_router_test.dart` 7/7 pass. | ✓ Covered |
| AC-13 | `flutter build apk --debug` exit 0 in Task 002 verification. Gen-l10n correctness transitively validated by tests compiling against generated `app_localizations*.dart`. | ✓ Covered (build gate) |
| AC-14 | `bugs/008-*.md` Status: Fixed, Fixed: 2026-05-18, `## Resolution` section present. | ✓ Covered (bookkeeping) |
| AC-15 | `docs/architecture.md` line 252 contains the new Conventions bullet. | ✓ Covered (bookkeeping) |

### Edge Case Gaps

- **Gap 1 (Material — maps to AC-2)** — `errorScreenBody` text (`"We couldn't find that destination."`) is not asserted by any test. Test 7 checks the AppBar title and the FilledButton label, but not the body Text. AC-2 explicitly lists the body as a required structural element. **Recommendation**: add one line `expect(find.text("We couldn't find that destination."), findsOneWidget);` to Test 7 after the existing `findsOneWidget` assertions on the error screen. One-line cost; closes the structural gap. **Note**: this is a test-thoroughness gap, not an AC unmet — AC-3 (which prescribes the exact Test 7 assertions) does NOT require the body assertion, and the structural fact that the body Text is in the source is verifiable by source review. Whether to close this gap is a `/verify`-time decision.

- **Gap 2 (Nice-to-have)** — German/Ukrainian locale variants of Test 7 would catch broken translations (gen-l10n validates key presence, not value correctness). Feature 010 demonstrates the locale-resolved test pattern.

- **Gap 3 (Low priority)** — `automaticallyImplyLeading: false` is not asserted by any test. `find.byType(BackButton) findsNothing` would lock the UX contract in. Plan accepts this as visually verified.

- **Gap 4 (Low priority)** — Deeper paths (`/meds/invalid/deeply/nested`) exercise the same `errorBuilder` code path as `/nonexistent`. Not a real coverage gap (uniform GoRouter behavior); spec deliberately uses one segment as representative.

- **Gap 5 (Future — out of scope)** — Tab-stack state preservation across error→recovery. Test 7 only verifies `HomeScreen` reappears; doesn't verify Meds branch stack is intact if user was deep in Meds before erroring. Natural extension of Test 4's sentinel pattern in a future spec.

- **Gap 6 (Theoretical)** — Repeated error → error navigation. Not recursive in GoRouter by design; spec out-of-scope excludes this surface.

---

## Forward-looking notes (for the team)

1. **Deep-link enablement spec** (future): When `<intent-filter android:scheme="...">` or `CFBundleURLTypes` is added, the same PR MUST add `GoRouter.redirect:` with an allow-list of supported deep-link shapes. The `errorBuilder` is the safety net, not the policy.
2. **Translation QA pass** (low priority): The Ukrainian `errorScreenBody` translates as "Не вдалося знайти цей маршрут." ("route" rather than "destination"). Spec-faithful to AC-6 verbatim, but a native-speaker pass might prefer "сторінку" for consistency with the title.
3. **Test thoroughness** (Gap 1): one-line addition to Test 7 to cover AC-2's body element — judgment call for `/verify`.

---

Next: Run `/verify` to render the AC-by-AC verdict.
