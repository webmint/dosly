# Research: Surface Settings Persistence Errors

**Date**: 2026-05-07
**Signals detected**: First Riverpod stream-based error signal pattern in the codebase; first `ref.listen` usage; first `SnackBar` / `ScaffoldMessenger` usage. Codebase grep confirmed zero pre-existing usages in `lib/` or `test/`.

## Questions Investigated

1. **Q**: What's the Riverpod 3.x canonical pattern for bridging a `StreamController` owned by a `Notifier` to a `StreamProvider` that other code can `.listen` to?
   **Finding**: The canonical pattern matches the spec's chosen shape. From the Riverpod 3.0.2 docs (Context7 `/rrousselgit/riverpod/riverpod-v3.0.2`):
   - `ref.onDispose(() => controller.close())` is the documented cleanup mechanism for `StreamController` ownership inside a provider's `build()`.
   - A `StreamProvider` can wrap a `Stream` returned from elsewhere — the provider pattern `(ref) => ref.watch(otherProvider.notifier).errors` is supported.
   - The `Notifier` class explicitly says "logic should not be placed in the constructor of your notifier, as ref and other properties aren't yet available at that point. Instead, put your logic in the `build` method." So the controller MUST be initialized inside `build()`, not as a field initializer.
   **Decision**: `SettingsNotifier` will declare `late final StreamController<Failure> _errors;` and initialize it inside `build()` along with `ref.onDispose(_errors.close)`.

2. **Q**: For showing a SnackBar on stream emission, should `SettingsScreen` be a `ConsumerWidget` with `ref.listen` in `build`, or a `ConsumerStatefulWidget` with `ref.listenManual` in `initState`?
   **Finding**: Both are documented official patterns. From Context7:
   - `ConsumerStatefulWidget + ref.listenManual(...)` in `initState` — used when you want the listener attached at widget-creation and outliving `build`. Useful when also needing other state (controllers, animations).
   - `ConsumerWidget + ref.listen(...)` in `build` — the simpler "safe and recommended way to listen to providers within widgets, triggering side-effects whenever the watched provider changes." `ref.listen` does not cause rebuilds — it only fires the callback on change.
   The current `SettingsScreen` is a plain `StatelessWidget` with no other state. Adding `ref.listen` to a `ConsumerWidget.build` is a strictly smaller change than introducing `ConsumerStatefulWidget` ceremony.
   **Decision**: `ConsumerWidget` + `ref.listen<AsyncValue<Failure>>(settingsErrorsProvider, ...)` inside `build`. Use `whenData((_) { ... showSnackBar })` to trigger only on actual emission (skips the initial `AsyncLoading` from a fresh subscription).

3. **Q**: Should `settingsErrorsProvider` be `autoDispose` or non-autoDispose?
   **Finding**: `settingsProvider` (the parent) is declared as `final settingsProvider = NotifierProvider<...>(SettingsNotifier.new)` — non-`autoDispose`. App settings are app-wide and live for the lifetime of the app. The error stream is a side-channel of the same notifier; making it autoDispose while the parent isn't would create a confusing lifecycle mismatch.
   **Decision**: `final settingsErrorsProvider = StreamProvider<Failure>((ref) => ref.watch(settingsProvider.notifier).errors);` — non-`autoDispose`, matches parent.

4. **Q**: Will the `StreamController` registered via `ref.onDispose(_errors.close)` actually be cleaned up correctly?
   **Finding**: Yes. Per Riverpod 3.x docs: "The onDispose callback is called automatically during state destruction." Since `settingsProvider` is non-`autoDispose`, "state destruction" only happens when the `ProviderContainer` itself is disposed (typically test teardown via `container.dispose()`, or app shutdown). For the production app this means the controller lives for the entire app lifetime, which is fine — broadcast `StreamController`s with no buffered messages have negligible memory footprint. For tests, the existing `tearDown(() { container.dispose(); })` in `settings_provider_test.dart` already triggers the cleanup correctly.
   **Decision**: No special test setup needed. The existing `ProviderContainer` test pattern works.

5. **Q**: Should the SnackBar use `SnackBarBehavior.floating` or the legacy fixed/anchored behavior?
   **Finding**: Material 3 design guidelines recommend `floating` for modern apps — the SnackBar appears as a floating card above the content. The legacy `fixed` behavior anchors to the bottom edge (used to overlap bottom navigation in older patterns). The dosly app uses `useMaterial3: true` throughout.
   **Decision**: `SnackBarBehavior.floating` — matches the M3 design language.

6. **Q**: For the widget-level error-path test, how should we override the provider — fake repo or fake notifier?
   **Finding**: Two patterns:
   - **Override `settingsRepositoryProvider`** with a fake repo that has per-method `failOnSaveX` flags (matches the existing `_FakeSettingsRepository` in `settings_provider_test.dart`). Pro: exercises the real `SettingsNotifier`, real fold logic, real `StreamController`. Con: requires the fake to be redeclared in the screen test file (Dart doesn't easily share private classes across test files; `_FakeSettingsRepository` is private with a leading underscore).
   - **Override `settingsProvider`** with a hand-rolled notifier. Pro: total control. Con: bypasses the very fold logic this spec is testing — defeats the point of the integration test.
   **Decision**: Override the repository, not the notifier. Redeclare a `_FakeSettingsRepository` in the screen test file (or rename the existing one to expose `failOnSaveX`). Keeps the test pyramid honest — the unit test (in `settings_provider_test.dart`) verifies the fold + stream emission; the widget test (in `settings_screen_test.dart`) verifies the provider → screen → SnackBar wiring on top of a real notifier.

## Alternatives Compared

### Failure-surfacing architecture

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **A. `AsyncNotifier<AppSettings>`** | "Errors as first-class state" via `AsyncValue.error`. Idiomatic Riverpod for async-loading state. | Wraps the entire state in `AsyncValue`. All four `.select(...)` consumers in `app.dart` plus the two selectors and theme preview must `.when(data:, error:, loading:)`-unwrap. Initial load is genuinely sync — there's no "loading" state to represent. Mutator-level errors don't represent state-error (state stays consistent with what was saved). | **Rejected** (decided in spec §2) |
| **B. Side-channel `StreamProvider<Failure>`** | Smallest blast radius — only `SettingsNotifier` and `SettingsScreen` change. State shape unchanged. Mutator return types unchanged. Other consumers (app.dart, selectors, theme preview) untouched. Idiomatic Riverpod (StreamController + ref.onDispose pattern is in the docs). | First StreamController + ref.listen + SnackBar pattern in the codebase — slight pattern-overhead. Stream lifecycle (broadcast, onDispose) needs care. | **Chosen** (decided in spec §2) |
| **C. Mutators return `Future<Either<Failure, void>>`** | No new provider. Failure handling explicit at call sites. | All four mutator call sites (theme_selector × 2, language_selector × 2, theme_preview_screen × 3+) need rework. Each needs its own SnackBar plumbing — the screen-level error UI duplicates across widgets. theme_preview_screen would need throwaway error UI for a screen scheduled for removal. | **Rejected** (decided in spec §2) |
| **D. Sealed `Loaded \| Error` state union** | "Errors as first-class state" without async. | Same blast radius as A (every consumer pattern-matches the union) with extra ceremony. No clear win over A. | **Rejected** (decided in spec §2) |

**Decision (re-confirmed)**: **B** — side-channel `StreamProvider<Failure>`. The Riverpod 3.x docs validate every component of this pattern (StreamController-from-Notifier, ref.onDispose, ref.listen-with-AsyncValue, ConsumerWidget).

### Listener placement for the SnackBar

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **`ConsumerWidget` + `ref.listen` in `build`** | Simplest. No `initState` boilerplate. SettingsScreen has no other state. Documented as the "safe and recommended way." | None for this case — listener is recreated on each build but `ref.listen` is identity-checked by Riverpod, so it doesn't fire spuriously. | **Chosen** |
| **`ConsumerStatefulWidget` + `ref.listenManual` in `initState`** | Listener attached once at widget creation. Useful when widget already needs initState (animations, controllers). | SettingsScreen has no other state. Adds `State` class boilerplate for no gain. | **Rejected** |

## References

- Context7 `/rrousselgit/riverpod/riverpod-v3.0.2`:
  - `packages/riverpod/dartdoc/providers.md` — `ref.onDispose` + `StreamController.close` example
  - `website/docs/concepts2/refs.mdx` — `Consumer + ref.listen` example
  - `website/docs/concepts2/providers.mdx` — Notifier class lifecycle (build vs constructor)
  - `llms.txt` — `ConsumerStatefulWidget + ref.listenManual + ScaffoldMessenger.showSnackBar` example
- Spec 014: `specs/014-surface-settings-errors/spec.md` (architectural choice rationale in §2)
- Bug 003: `bugs/003-silent-error-swallowing-fold.md` (originating bug, Option A/B sketches)
- MEMORY.md Feature 013 lesson: empty closure with deferral comment was the right interim state; this spec is the planned next step.
- pubspec.yaml: `flutter_riverpod: ^3.3.1` confirmed.
