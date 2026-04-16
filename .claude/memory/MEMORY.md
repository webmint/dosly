# Project Memory — dosly

## Project Identity
**dosly** is a personal cross-platform (iOS + Android) medication tracking app. Fully local — no backend, no accounts, no telemetry. Tracks medications, schedules, intake confirmations, and adherence history. Constitution at `constitution.md` is the source of truth.

## Project Structure
Greenfield Flutter app — `flutter create .` has run, scaffolding is in place. `linux/`, `macos/`, `web/`, `windows/` were removed (iOS + Android only). No feature code yet — first scaffolding step is `lib/core/error/failures.dart` per constitution Section 7.1.

## Key File Paths
- `lib/main.dart` — app entry point (currently `flutter create` boilerplate; replace when first feature lands)
- `lib/core/` — cross-feature utilities (does not exist yet — create per Section 7.1):
  - `lib/core/error/failures.dart` — sealed `Failure` freezed union
  - `lib/core/clock/app_clock.dart` — injectable `Clock` for time-sensitive tests
  - `lib/core/database/database.dart` — drift database singleton
  - `lib/core/database/tables/` — drift table definitions
  - `lib/core/database/migrations/` — versioned migration files
  - `lib/core/notifications/notification_service.dart` — `flutter_local_notifications` wrapper
  - `lib/core/permissions/permission_service.dart` — `permission_handler` wrapper
  - `lib/core/routing/app_router.dart` — `go_router` config
  - `lib/core/theme/app_theme.dart` — Material 3 ThemeData
  - `lib/core/logging/logger.dart` — typed logger with PHI sanitize layer
- `lib/features/[feature]/domain/` — pure Dart: entities, value objects, abstract repository contracts, use cases. **No Flutter, drift, or third-party SDK imports allowed here.**
- `lib/features/[feature]/data/` — drift data sources, DTOs, mappers, repository implementations
- `lib/features/[feature]/presentation/` — `@riverpod`-annotated providers, screens, widgets
- `test/` — mirrors `lib/`
- `pubspec.yaml` — dependencies (currently has only `cupertino_icons` and `flutter_lints`; full list in constitution Section 7.3)
- `analysis_options.yaml` — replace default with strict-mode config from constitution Section 7.4
- `constitution.md` — non-negotiable rules (project root)

## Workspace Configuration
- **Mode**: standalone
- **Source Root**: .
- **Platforms**: iOS + Android
- **Backend**: none (fully local-on-device)

## Architecture Decisions
<!-- Why decisions were made, not just what -->

- **Clean Architecture (data/domain/presentation per feature)** — chosen during `/setup-wizard`. Rationale: enforces dependency direction, makes domain logic unit-testable in pure Dart, isolates third-party SDK choices in `data/`.
- **`Either<Failure, T>` via fpdart** — chosen during `/setup-wizard`. Rationale: explicit error flow at repository boundaries; pairs naturally with Riverpod's `AsyncValue` in the UI; eliminates the "did I forget try/catch?" class of bugs.
- **Riverpod 2.x with `riverpod_generator` codegen** — chosen during `/setup-wizard` and `/constitute`. Rationale: less boilerplate than BLoC, autoDispose by default with codegen, built-in DI removes need for `get_it`, `AsyncValue<T>` composes cleanly with `Either<Failure, T>`.
- **`freezed` for entities, DTOs, and sealed unions** — chosen during `/constitute`. Rationale: hand-rolled equality is bug-prone; freezed gives `==`, `hashCode`, `copyWith`, sealed unions, and JSON for free.
- **`drift` for the local SQLite database** (over sqflite/isar) — chosen during `/constitute`. Rationale: typed queries, strong migration tooling, pairs cleanly with strict mode. Isar is in maintenance; sqflite is untyped strings.
- **`go_router` for routing** — chosen during `/constitute`. Rationale: official Flutter routing solution, supports deep links and type-safe routes.
- **`flutter_test + mocktail` for testing** — chosen during `/setup-wizard`. Rationale: no codegen step (unlike mockito), null-safe, official runner.
- **No backend / fully local** — chosen during `/constitute`. Rationale: medication data is sensitive PHI; eliminating cloud sync is the strongest privacy posture and simplest architecture.
- **Maximum strictness lint mode** (`strict-casts`, `strict-inference`, `strict-raw-types`, no `dynamic`, no `!`) — chosen during `/constitute`. Rationale: medication tracking is safety-relevant; type-system bugs can cause real harm.
- **All timestamps in UTC, displayed in local** — Rationale: prevents DST and time-zone bugs in adherence calculations.
- **`Clock` injection over `DateTime.now()`** — Rationale: scheduling and adherence logic is the heart of the app; tests must control time.

## Naming Conventions

- **Filenames**: `snake_case.dart` (Effective Dart)
- **Types / classes / widgets / enums**: `UpperCamelCase`
- **Variables / parameters / methods**: `lowerCamelCase`
- **Constants**: `lowerCamelCase` (Dart style, NOT `SCREAMING_SNAKE_CASE`)
- **Private members**: leading underscore `_thing`
- **Use cases**: imperative verb phrase, one operation per class — `AddMedication`, `MarkIntake`, `GetTodaySchedule`
- **Repositories (abstract)**: noun + `Repository` — `MedicationRepository`
- **Repository implementations**: `<Name>RepositoryImpl` in `data/repositories/`
- **Failures**: noun + `Failure` suffix
- **Entities**: domain noun, no suffix — `Medication`, `Schedule`, `Intake`
- **DTOs**: entity name + `Model` suffix — `MedicationModel`
- **Drift tables**: plural PascalCase — `Medications`, `Intakes`
- **Riverpod providers (codegen)**: `xxxProvider` auto-generated from `@riverpod` annotated function

## Domain Cheat Sheet

- **Entities**: `Medication`, `MedicationForm` (enum: tablet, capsule, injection, syrup, drops, inhaler, cream, sachet), `MedicationType` (sealed: `Course` | `Permanent`), `Dosage`, `Schedule`, `TimeSlot`, `Intake`, `IntakeStatus` (pending, taken, missed, skipped), `AdherenceRecord`, `Settings`
- **Intake state machine**: `pending → taken/skipped/missed`. `taken → pending` allowed within `gracePeriodMinutes` (undo).
- **Adherence formula**: weekly = `sum(taken across week) / sum(scheduled across week)`. Skipped intakes do NOT count toward scheduled. Future intakes don't dilute the ratio.
- **Default settings**: `gracePeriodMinutes = 5`, `intakeWindowMinutes = 120`, `notificationLeadMinutes = 0`
- **Privacy rule**: notification text must NOT contain medication names — generic "Time for your medication" + tap to view details

## Known Pitfalls
<!-- Populated during work as mistakes are discovered -->

- **`package:flutter/*` in `domain/`** — strictly forbidden. Domain must run in pure Dart tests.
- **`package:drift/*` or `package:flutter_local_notifications/*` in `domain/`** — also forbidden. Wrap in repositories / services.
- **`!` null assertion** — every use is a latent runtime crash. Use explicit null checks or pattern matching.
- **`SharedPreferences` for medication/intake data** — never. That's the system of record; it goes in drift.
- **`ref.read` inside provider `build`** — breaks reactivity. Use `ref.watch`.
- **`DateTime.now()` in domain code** — never. Inject `Clock` and use `Clock.now()` so tests can fake time.
- **Direct `flutter_local_notifications` calls from features** — never. Always go through `core/notifications/notification_service.dart`.
- **Logging medication names** — forbidden. PHI even for personal use.
- **Drift schema changes without bumped `schemaVersion` and migration** — never drop or alter columns blindly; this is health data, do not lose it.
- **`BuildContext` after `await` without `mounted` check** — `use_build_context_synchronously` lint catches this; keep it on.
- **Assuming Flutter's default locale fallback lands on English** _(Feature 006, Task 007)_: `flutter gen-l10n` emits `supportedLocales` alphabetically by locale code — for `[de, en, uk]` the list starts with `de`, not `en`. Flutter's default `BasicLocaleListResolutionCallback` falls back to the FIRST entry when no match, so unsupported device locales silently resolve to German. **Fix**: always wire an explicit `localeResolutionCallback` that matches by `languageCode` and returns `const Locale('en')` (or the intended fallback) explicitly. Never rely on list ordering. Discovered only because a `Locale('fr')` test asserted English strings and failed — confirms the value of testing unsupported-locale fallback, not just supported locales.
- **Context7 / docs lag Flutter SDK reality** _(Feature 006, Task 002)_: Research said `synthetic-package: false` is the modern recommendation. Flutter 3.41+ has **fully retired** the option entirely — any value emits a deprecation warning. Lesson: when adopting Flutter config flags mentioned in docs, also run `flutter pub get` and read the stderr. Omitting the flag = current desired behavior. Treat Flutter migration docs as "at least this old" and verify against the running toolchain.

## What Worked
<!-- Patterns and approaches that solved problems well -->

- **Hand-coded `const ColorScheme` literals + per-hex assertion tests** _(Feature 001)_: 70 per-field `expect(scheme.x, const Color(0x...))` tests catch any design drift instantly. Matched spec §9 drift-protection intent. Total cost: ~120 lines of test file, huge ROI.
- **SHA-256 hashing for bundled font assets** _(Task 001)_: `SOURCE.md` records hashes of all four Roboto TTFs. Security-reviewer independently verified them — excellent supply-chain hygiene for a personal app. Consider promoting to a CI check later.
- **`ValueNotifier<ThemeMode>` + `ListenableBuilder` for app-wide theme state** _(Task 004+008)_: zero dependencies, built into Flutter, trivially testable, pairs cleanly with `MaterialApp.themeMode`. Appropriate choice when you don't need Riverpod yet.
- **Task bundling for mechanical glue work** _(spec 001 breakdown)_: bundling "create data structure + write data-assertion tests" into one task (Task 002, Task 004) kept the breakdown to 8 tasks instead of 11 without losing rigor. Matched `_multi-task-continuation.md` bundling rule.
- **Deferring manual cross-platform run to user** _(Task 008 + AC-13)_: sandbox can't drive simulators. Widget smoke test exercises the compile pipeline so AC-13 is the ONLY gap at verify time, and it's clearly scoped as "user runs `flutter run -d ios/android` after merge."
- **`ListenableBuilder` + `MaterialApp.router` + top-level `GoRouter` constant coexist cleanly** _(Task 004, Feature 002)_: Wrapping `MaterialApp.router(routerConfig: appRouter)` in a `ListenableBuilder(listenable: themeController)` rebuilds `MaterialApp.router` on theme change without resetting `GoRouter`'s internal navigation stack. The `GoRouter` instance is a top-level `final` constant (same shape as `themeController`); `MaterialApp.router` re-reads `routerConfig` on each build but doesn't reconstruct the router. Confirmed by `flutter test` passing through navigation-then-cycling in one test flow. This is the reactive-theme-plus-go_router pattern dosly will use going forward.
- **Integration-gate task ordering for UI refactors** _(Task 004 → 005, Feature 002)_: When swapping `MaterialApp` for `MaterialApp.router`, the existing widget tests that assert on the old `home:` target will fail at task 004 completion. Correct response: task 004's `Done when` deliberately OMITS `flutter test` (gates only on `dart analyze`), and task 005's `Done when` includes `flutter test` + `flutter build apk --debug` as the integration verification point. Kept the breakdown honest and avoided a spurious "task 004 broke tests" panic.
- **`lucide_icons_flutter` package is the right Lucide fit for Flutter** _(Feature 004)_: Package name is `lucide_icons_flutter` (NOT `lucide_icons` — that's a different/older package). Import is `package:lucide_icons_flutter/lucide_icons.dart`, class is `LucideIcons`, API is `static const IconData` drop-in for `Icons.*`. Version ^3.1.12 tree-shakes unused glyphs in release builds. All standard Lucide names compile in lowerCamelCase (verified: `pill`, `house`, `settings`, `history`, `circlePlus`, `thermometer`, `syringe`, `glasses`, `droplets`, `activity`, `clock`, `check`, `chevronDown`, `chevronRight`, `arrowLeft`, `search`, `plus`, `eye`, `x`, `phone`, `sunMoon`, `sun`, `moon`). No name surprises — follow lucide.dev naming directly.
- **Two-task breakdowns for mechanical swaps are fine** _(Feature 004)_: A dependency-add + icon-swap migration across 2 screens doesn't need 4 tasks. Task 001 (infra: add dep) + Task 002 (presentation: swap + showcase) cleanly separated by layer. Splitting icon swap into per-screen tasks would have been over-granularization.
- **Top-level `_noop(int _) {}` preserves `const` on widgets with required callback params** _(Feature 005, Task 001)_: Flutter widgets like `NavigationBar` require `onDestinationSelected` to be supplied. An inline lambda `(_) {}` is NOT `const`-compatible, so `const HomeBottomNav()` would fail to compile if the widget embedded one. Workaround: declare a private top-level function `void _noop(int _) {}` in the same file and pass it by reference — top-level functions ARE const-compatible in Dart, so `const HomeBottomNav()` works at every call site. Use this pattern for any "presentational only, will-become-real-later" widget that wraps a Material control with a required callback.
- **Flutter built-in `NavigationBar` delivers M3 pill-indicator + ColorScheme theming for free** _(Feature 005)_: The spec asked for a widget that "looks exactly like" an HTML `.bot-nav` with surface-container bg, secondary-container pill, on-surface-variant → on-surface label color swap. `NavigationBar` does all of this automatically by reading `Theme.of(context).colorScheme` — zero `NavigationBarThemeData` customization, zero hard-coded colors, zero light/dark duplication. When the HTML design was generated from Material Theme Builder (as here), the built-in widget is the answer; custom Row-based replicas are churn.
- **Two-task breakdown with per-task integration-gate separation stayed honest** _(Feature 005)_: Task 001 (widget + wire, gated on `dart analyze` + existing-test no-regression) and Task 002 (widget test, gated on full `flutter test` + `flutter build apk --debug`) followed the Feature 002 pattern — pushing the build/test integration gate to the terminal task of the feature. Both tasks' done-when conditions were satisfiable independently, and the full gate ran exactly once. No repair loops needed.
- **Reviewing inert/stateless widgets rarely turns up findings** _(Feature 005)_: Security-reviewer + performance-analyst + qa-engineer all returned clean verdicts on a 3-file, no-I/O, no-state presentation change. Takeaway: keep /review in the pipeline even for tiny features (the "nothing found" report is itself a useful provenance record for audit mode), but don't expect it to justify expanding the widget. For future presentation-only micro-features, the review pass is cheap insurance but not a bottleneck.
- **Centralize sanctioned `!` null-assertions via a `BuildContext` extension** _(Feature 006, /review hardening)_: When the constitution forbids `!` but a framework pattern demands it (e.g., Flutter's `AppLocalizations.of(context)!`), hide it in a named getter: `extension AppLocalizationsContext on BuildContext { AppLocalizations get l10n => AppLocalizations.of(this)!; }`. Consumer widgets call `context.l10n.xxx` with zero `!` at the call site. Net effect: exactly one auditable `!` site in the entire codebase instead of N (one per widget). Scales perfectly — adding a new localized widget adds zero new `!` sites. Pattern should be reused for any future "framework returns nullable but it's never null in practice" primitive.
- **`/review` surface-area catches drift that per-task `code-reviewer` misses** _(Feature 006)_: Per-task code review looked at each changed file in isolation and never noticed that the feature had ended up with TWO `!` sites across the codebase (each file had its own compliant `1 !`, but the aggregate was 2). The feature-wide security-reviewer running during `/review` caught it immediately. Takeaway: keep `/review` in the pipeline even when per-task reviews all passed — feature-level security review surfaces aggregate-level issues (total `!` count, dependency pinning consistency, PHI exposure across surfaces) that single-file reviews cannot.
- **Running `/review` findings can still be fixed before `/verify`** _(Feature 006)_: Medium-severity review findings (unpinned dep + 2 `!` sites) were raised during `/review`, user asked to fix both, fixes applied (intl pinned + extension introduced), verified clean, then `/verify` ran. review.md stayed as the time-of-review snapshot; verify.md documented the follow-up resolution. This is the right pattern — don't re-run `/review` after every micro-fix, but do note the resolution trail in the verify report for audit clarity.
- **When `/review` finds a Medium severity finding, the Settings feature or post-MVP cleanup is NOT the default destination** _(Feature 006)_: Tempting to defer "Medium" to "later" but the cost of fixing while code is fresh is tiny; the cost of fixing later (with new context, forgotten reasoning, churned codebase) is large. For small Medium findings (< 20 lines to fix), the right default is fix-now. For larger ones, defer — but record a bug file so the deferral is visible.

## What Failed
<!-- Approaches that were tried and didn't work — avoid repeating these -->

- **Over-trusting task-spec license claims** _(Task 001)_: the task spec said Roboto is Apache 2.0; implementer correctly discovered it's actually OFL 1.1 in v3 and shipped the right license. Lesson: when specifying licenses in future tasks, VERIFY the current license of the specific version being shipped, don't rely on historical knowledge.
- **Test coverage gaps for getter-based code** _(Feature 001, AC-4)_: `AppTheme.lightTheme`/`darkTheme` are getters with no dedicated test. Review caught it. Lesson: for any new `lib/core/` file, plan a corresponding test file during `/plan`, not as an afterthought. Dedicated test files for `app_theme.dart`, `app.dart`, and `theme_preview_screen.dart` would close the gap at ~35 total lines.
- **`pubspec.yaml` `weight: N` comments in task specs can desync** _(Task 001)_: task spec said Bold/Light are important but the actual type scale only uses w400/w500. Those weights are dead code until someone uses them. Lesson: when declaring font weights, cross-check against the actual `TextStyle` usages in the type scale, not just "what a design spec lists."
- **Over-prescriptive "exact imports" lists in task files** _(Task 003, Feature 002)_: task file mandated 4 imports including `package:flutter/material.dart`, but material.dart was genuinely unused — `go_router` transitively provides `BuildContext` via its internal `widgets.dart` import, and screen types came from their own relative imports. First agent attempt added `// ignore: unused_import` to satisfy both constraints; this was rejected as a lint-suppression anti-pattern and a repair round dropped the import entirely. Lesson: when writing task files, do not enumerate "exact" import lists unless you've verified every listed package is actually referenced in the file body. Prefer "minimum sufficient imports to make X compile and pass analyze" over literal lists.

## External API Quirks
<!-- Unexpected behavior from APIs, libraries, or services this project uses -->

- **`flutter_local_notifications` + DST**: must use `matchDateTimeComponents: DateTimeComponents.time` so a 09:00 reminder fires at 09:00 local both before and after a DST shift. Combined with the `timezone` package for IANA zones.
- **Android 12+ exact alarms**: `SCHEDULE_EXACT_ALARM` (or `USE_EXACT_ALARM` for Android 13+ apps that qualify) must be granted at runtime; check via `permission_handler`.
- **Android 13+ notifications**: `POST_NOTIFICATIONS` is a runtime permission, not just a manifest declaration.
- **Roboto font licensing** _(spec 001 / Task 001)_: Roboto v3 (the modern Google Fonts release) is **SIL OFL 1.1**, NOT Apache 2.0. Only the original 2011 Roboto was Apache 2.0. Always ship `OFL.txt` (not `LICENSE.txt`/Apache) with bundled Roboto assets.
- **Roboto static weight source** _(spec 001 / Task 001)_: `github.com/google/fonts/apache/roboto/static/` no longer exists; the canonical source for static Roboto weights is the `googlefonts/roboto-3-classic` GitHub release (e.g. `Roboto_v3.015.zip` → `android/static/`). The `google/fonts` repo only ships the variable font now.
- **Flutter `ColorScheme` field rename** _(spec 001 / Task 002)_: `inverseOnSurface` was renamed to `onInverseSurface` in modern Flutter. The HTML Theme Builder output uses `--md-inverse-on-surface` (which matches the new name semantically, not the old one). Modern code MUST use `onInverseSurface`.
- **Deprecated `surfaceVariant` field** _(spec 001 / Task 002)_: removed from `ColorScheme`. Material Theme Builder still emits `--md-surface-variant` in HTML output, but it must be DROPPED — replaced by `surfaceContainerHighest` per Flutter migration guidance.
- **`Color.toARGB32()` vs `Color.value`** _(spec 001 / Task 007)_: `Color.value` is deprecated in modern Flutter (3.27+). Use `c.toARGB32()` to get the 32-bit ARGB int. Works on Flutter SDK ^3.11.1.
- **`unnecessary_import` lint trap** _(spec 001 / Task 004)_: `package:flutter/foundation.dart` is REDUNDANT when `package:flutter/material.dart` is already imported (material re-exports `ValueNotifier`, `ChangeNotifier`, etc.). Importing both fails strict-mode `dart analyze`. Pick one — usually `material.dart` for widget code.
- **`lucide_icons_flutter` vs `lucide_icons`** _(Feature 004)_: Two similarly-named Flutter packages exist on pub.dev. `lucide_icons_flutter` (v3.x) is the actively maintained one — `lucide_icons` is older/abandoned. Always specify the full name when adding the dependency.
- **`NavigationBar` has NO `const` constructor** _(Feature 005 fix)_: Assumed `const NavigationBar(...)` would work because all its args are const-compatible. It doesn't — Flutter's `NavigationBar` does not declare a `const` constructor at all, regardless of args. You cannot wrap a parent in `const` if `NavigationBar` is inside. Apply `const` at the deepest possible leaves instead: `const Divider(...)`, `const <NavigationDestination>[...]`, each `const NavigationDestination(...)`. The outer `Column` + `NavigationBar` must be non-const.
- **M3 `Divider(height: 1, thickness: 1)` with no `color:` == `ColorScheme.outlineVariant`** _(Feature 005 fix)_: In a Material 3 theme (`useMaterial3: true`), the default `Divider.color` falls through `DividerTheme.color` → `colorScheme.outlineVariant`. Exactly matches the HTML `var(--md-outline-variant)` token. Don't pass `color:` explicitly — the theme default is both correct and dark-mode-aware. Note: `Divider` defaults are `height: 16, thickness: 0` (hairline with vertical padding); you MUST pass `height: 1, thickness: 1` for a flush 1-px line.
- **Generic helper params block `const` on Icon widgets** _(Feature 004, performance review)_: A helper like `Widget _iconTile(IconData icon, String label) => ... Icon(icon, size: 32) ...` cannot produce a `const` Icon because `icon` is a parameter. For showcase/grid lists that render many fixed icons, prefer a `const _IconTile(icon: LucideIcons.pill, label: 'pill')` stateless widget so each call site is a canonical constant. Acceptable to skip on temporary dev scaffolding.
- **`StatefulNavigationShell.goBranch` tearoff IS directly assignable to `ValueChanged<int>`** _(Feature 007, Task 004)_: `goBranch` has signature `void goBranch(int index, {bool initialLocation = false})`. In Dart, a function with additional optional-named parameters is a subtype of one without them, so `onDestinationSelected: navigationShell.goBranch` compiles cleanly — no lambda wrapper needed. `initialLocation` defaults to `false`, meaning tap-on-already-selected restores the branch's last location (effective no-op at branch root), which is exactly the plan's "tap-on-selected behavior" decision. Reuse this pattern for any future go_router shell wiring.
- **Test-only `GoRouter` instances isolate StatefulShellRoute branch-stack verification** _(Feature 007, Task 005)_: Production `appRouter` has no sub-routes under any branch yet, so testing `StatefulShellRoute`'s branch-stack-preservation contract requires an extra child route. The clean approach is a test-local `GoRouter` built in a `_buildTestRouterWithSentinel()` helper inside the test file — same shape as production, plus one child `GoRoute('sentinel', builder: (_, __) => const _SentinelScreen())` under the Meds branch. Dispose the test-local router at the end of each test with `testRouter.dispose()` to avoid leaked-`ChangeNotifier` warnings. Production `appRouter` stays clean. This pattern generalizes: any time you need to test routing behavior that depends on routes the production app doesn't need yet, declare a test-local router rather than adding placeholder routes to production.
- **`GoRouter.of(tester.element(find.byType(X)))` is the `!`-free way to get router context in tests** _(Feature 007, Task 005)_: For integration tests that need to programmatically navigate, `tester.element(find.byType(HomeBottomNav))` (or any widget guaranteed to be under the router) returns a non-null element whose `BuildContext` is under the `MaterialApp.router`. `GoRouter.of(context)` is non-null there. No `!` needed — aligns with constitution §3.1.
- **M3 `Divider` stored values matter for regression tests** _(Feature 007, Task 002)_: A bare `const Divider()` stores `null` for both `height` and `thickness` at the widget level, even though the rendered output is indistinguishable. A regression-guard test like `dividers.any((d) => d.height == 1 && d.thickness == 1)` will NOT match a `null`-stored divider. When a widget test is the spec's proof-of-contract for "1-px divider", pass explicit `height: 1, thickness: 1` at the widget construction site — don't rely on theme defaults at the test-predicate level, even though you should still rely on them for `color:`.
- **Integration-gate task pattern scales to 5-task features** _(Feature 007)_: The Feature 002 / Feature 005 pattern of putting `flutter test` + `flutter build apk --debug` on the TERMINAL task only (not per-task) worked again for a 5-task feature with mid-feature signature migrations. Intermediate tasks gated only on `dart analyze` + scope-specific `flutter test test/features/X/`. Breaking the HomeBottomNav signature in Task 001 cascaded to `home_screen.dart` and both test files in the SAME task, so no interim task saw broken state. Keep this pattern for any feature where an early task changes a widely-consumed signature.
- **Presentation-only features pass review cleanly — keep `/review` in the pipeline anyway** _(Feature 007)_: Feature 007 was 11 files, zero `!`/no dynamic/no color literals, no data/domain layers. All three review agents (security, performance, qa) returned zero Critical/High/Medium findings. Only Info/Low deferral notes (deep-link errorBuilder, tearoff allocation, test-isolation concerns). Consistent with Feature 005 precedent. The value of running `/review` is the aggregate-level audit trail + forward-looking advice, not finding bugs. Keep running it even when the diff looks trivially safe.

## Performance Notes

- **Profile in profile mode**, never debug. Debug mode disables many optimizations and gives misleading numbers.
- **`const` constructors are free wins** — every widget that takes only compile-time constants should be `const`. The `prefer_const_constructors` lint enforces this.
- **`ListView.builder` over `ListView(children: [...])`** for any list that might exceed ~10 items.
- **Today's schedule resolution** runs on every app foreground; keep it pure and synchronous so the UI stays responsive.

## Pending Removals
<!-- Track APIs marked @Deprecated and the version they should be removed in -->
