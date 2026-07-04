# Task 006: Wire use-case providers + SettingsNotifier mutators

**Agent**: mobile-engineer
**Files**: `lib/features/settings/presentation/providers/settings_provider.dart` (+ regen `settings_provider.g.dart`)
**Depends on**: 005, 003
**Blocks**: 008, 011
**Context docs**: None
**Review checkpoint**: No

**Description**:
Expose the three new use cases as `@riverpod` providers and add three `SettingsNotifier` mutators, mirroring the existing `setThemeMode`/`setManualLanguage` mutators exactly: `await` the use case, then `fold(err → _errors.add(err), ok → state = state.copyWith(...))`. On failure the in-memory state is left unchanged. Keep the load-bearing `name: 'settingsNotifierProvider'` annotation argument. Mechanical — no new business logic.

**Change details**:
- Add imports for the three new use-case files.
- Add three `@riverpod` functions: `SetIntakeWindow setIntakeWindow(Ref ref) => SetIntakeWindow(ref.watch(settingsRepositoryProvider));` and the grace/mark-ahead equivalents.
- On `SettingsNotifier`, add:
  - `Future<void> setIntakeWindow(IntakeWindow window) async { final r = await ref.read(setIntakeWindowProvider).call(window); r.fold((f) => _errors.add(f), (_) { state = state.copyWith(intakeWindow: window); }); }`
  - `setGracePeriod(GracePeriod grace)` → `copyWith(gracePeriod: grace)`.
  - `setAllowMarkAhead(bool value)` → `copyWith(allowMarkAhead: value)`.
- Run `dart run build_runner build --delete-conflicting-outputs`.

**Contracts**:

### Expects
- `SetIntakeWindow`/`SetGracePeriod`/`SetAllowMarkAhead` exist (Task 005).
- `AppSettings` has `intakeWindow`/`gracePeriod`/`allowMarkAhead` (so `copyWith(...)` accepts them) (Task 003).
- `SettingsNotifier` exposes the `_errors` broadcast controller and the `fold`-based mutator idiom.

### Produces
- `settings_provider.dart` declares `setIntakeWindow`, `setGracePeriod`, `setAllowMarkAhead` `@riverpod` functions (generating `setIntakeWindowProvider`, etc.).
- `SettingsNotifier` declares methods `setIntakeWindow(IntakeWindow`, `setGracePeriod(GracePeriod`, `setAllowMarkAhead(bool` that call `copyWith` on success.

**Done when**:
- [x] `settings_provider.g.dart` regenerates cleanly.
- [x] On repo success each mutator updates only its target field via `copyWith`; on failure `state` is unchanged and the `Failure` is emitted on `errors`.
- [x] `dart analyze` passes on the provider file.

**Spec criteria addressed**: AC-12

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-03
**Files changed**: `settings_provider.dart` (+ regen `settings_provider.g.dart`)
**Contract**: Produces [all verified — 3 providers + 3 mutators; `settingsNotifierProvider` name preserved]
**Code review**: APPROVE (purely additive; existing 4 mutators/build()/errors byte-identical)
**Notes**: `name: 'settingsNotifierProvider'` untouched (function-form use-case providers need no `name:`). Mutator tests deferred to Task 011.
