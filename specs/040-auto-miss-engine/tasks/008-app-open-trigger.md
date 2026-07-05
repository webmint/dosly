# Task 008: Fire reconcile on app open + neutralize it in tests/harness

**Agent**: mobile-engineer
**Review checkpoint**: Yes (high-risk — `AppBootstrap` side-effect poisoning tests, MEMORY 035; first app-level integration)
**Files**: `lib/app_bootstrap.dart` (modify), `test/app_bootstrap_test.dart` (modify), `integration_test/support/app_harness.dart` (modify)
**Depends on**: 006
**Blocks**: None
**Context docs**: `docs/features/meds.md`

## Description

Trigger the auto-miss reconciliation once on app open, fire-and-forget and non-blocking, and — critically — make it neutralizable in tests. `AppBootstrap`'s `data:` branch reads `reconcileMissedOnOpenProvider` exactly like it reads `devSeedProvider` (side-effect only, never awaited on the path to `runApp`). Then override the reconcile in both the integration harness and the bootstrap unit test so the new startup side-effect cannot pollute golden flows or bootstrap assertions (the exact failure mode of the devSeed lesson, MEMORY 035).

## Change details

- In `lib/app_bootstrap.dart` (the `data:` branch, alongside the `kDebugMode` `devSeedProvider` read):
  - `ref.read(reconcileMissedOnOpenProvider);` (fire-and-forget; keepAlive → runs once). Import `features/meds/presentation/providers/intake_providers.dart`. Add a short comment: non-blocking on-open auto-miss (constitution §5.2 "on next app open"); errors are logged inside the provider, never surfaced as a startup error.
- In `integration_test/support/app_harness.dart` (the `overrides:` list, next to `devSeedProvider.overrideWith((ref) async {})`):
  - `reconcileMissedIntakesProvider.overrideWith((ref) => _NoOpReconcileMissedIntakes())` where `_NoOpReconcileMissedIntakes implements ReconcileMissedIntakes { @override Future<Either<Failure, int>> call({required DateTime now}) async => const Right(0); }`. Overriding the use-case provider neutralizes BOTH triggers (the on-open provider awaits the no-op). Update the harness "What it overrides" dartdoc list to mention the reconcile no-op.
- In `test/app_bootstrap_test.dart`:
  - Add the same `reconcileMissedIntakesProvider` no-op override to the test's `ProviderScope` overrides so the new side-effect doesn't run real repositories/DB during the existing assertions.

## Contracts

### Expects
- `reconcileMissedOnOpenProvider` (keepAlive) and `reconcileMissedIntakesProvider` exist (Task 006).
- `app_bootstrap.dart` has a `data:` branch that already does `ref.read(devSeedProvider)`.
- `app_harness.dart` builds a `ProviderScope` with an `overrides:` list containing `devSeedProvider.overrideWith((ref) async {})`.

### Produces
- `app_bootstrap.dart` reads `reconcileMissedOnOpenProvider` on the `data:` branch (fire-and-forget, not awaited).
- `app_harness.dart` overrides `reconcileMissedIntakesProvider` with a no-op that returns `Right(0)`.
- `app_bootstrap_test.dart` overrides `reconcileMissedIntakesProvider` with a no-op.

## Done when
- [x] App open fires the reconcile once, without blocking or erroring startup (bootstrap test still asserts the app mounts).
- [x] The integration harness and bootstrap test neutralize the trigger (no real reconcile in golden flows / bootstrap assertions).
- [x] Project-wide `dart analyze` clean; `flutter test test/app_bootstrap_test.dart` green; the integration golden suite still compiles.

**Spec criteria addressed**: AC-10, AC-15 (harness/bootstrap neutralization)

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-04
**Files changed**: `lib/app_bootstrap.dart`, `test/app_bootstrap_test.dart`, `integration_test/support/app_harness.dart`
**Contract**: Expects [confirmed] | Produces [3/3 verified]
**Notes**: `ref.read(reconcileMissedOnOpenProvider);` added on the `data:` branch — NOT awaited, NOT `kDebugMode`-gated (auto-miss is production behavior, unlike the debug-only seeder); the keepAlive provider folds/logs the Either so startup can't block or error. Neutralized by overriding `reconcileMissedIntakesProvider` with `_NoOpReconcileMissedIntakes` (`implements`, `call → Right(0)`) — added to the harness `overrides:` (one override neutralizes BOTH triggers, since on-open reads the use-case provider) and to all 5 `AppBootstrap` ProviderScope blocks in the bootstrap test. Full suite 791 pass; integration_test compiles. Code review: APPROVE. Info: harness dartdoc forward-references the Today trigger (Task 009) — becomes true when 009 lands.
