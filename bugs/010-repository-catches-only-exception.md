# Bug 010: Repository catches only `Exception`, lets `Error` (and other throwables) escape data layer

**Status**: Open
**Severity**: Warning
**Source**: audit (audits/2026-04-30-audit.md)
**Reported**: 2026-04-30
**Fixed**:

## Description

Constitution §3.2: "Every repository implementation catches its data-source
exceptions and returns `Left(Failure.x(...))`. Exceptions NEVER escape the
data layer."

All four `try/catch` blocks in `settings_repository_impl.dart` use
`on Exception catch (e)`. Throwables that extend `Error` (e.g. `StateError`,
`ArgumentError`, `RangeError`, `TypeError` — all of which the
`SharedPreferencesWithCache` platform bridge can plausibly throw on edge cases)
propagate upward unconverted, escaping the data layer and surfacing as raw
stack traces in callers.

Furthermore, `e.toString()` is used directly to populate
`CacheFailure.message`. On iOS/Android, platform-channel exception strings
typically include the absolute filesystem path of the on-disk plist/xml store.
Combined with bug 002's `debugPrint` of the failure object, paths can leak
into adb logcat / Xcode console of debug-built APKs (CWE-209-adjacent).

## File(s)

| File | Detail |
|------|--------|
| lib/features/settings/data/repositories/settings_repository_impl.dart | Lines 31–37 (saveThemeMode); 40–46 (saveUseSystemTheme); 51–57 (saveUseSystemLanguage); 62–68 (saveManualLanguage) |

## Evidence

`lib/features/settings/data/repositories/settings_repository_impl.dart:30–37`:
```
  @override
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode) async {
    try {
      await _dataSource.setThemeMode(mode);
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
```

The same pattern repeats × 4.

Reported by audit (architect F11, qa-engineer F8, security-reviewer F4).

## Fix Notes

Suggested approach (to be confirmed in `/fix`):

1. Replace `} on Exception catch (e) {` with `} catch (e, st) {` — catches all
   throwables (including `Error` subtypes) and captures the stack trace.
2. Once bug 006 lands (`Failure.unknown(Object error, StackTrace stack)`
   variant exists), route uncategorized failures to `Failure.unknown(e, st)`
   instead of `CacheFailure(e.toString())`. This avoids leaking platform
   strings into the message field.
3. Add a `_FailingDataSource` test double whose setters throw, and add four
   tests asserting `isA<Left<Failure, void>>()` on the result. Pairs with the
   qa-engineer F8 finding (closes the "exceptions never escape data layer"
   contract test gap).

Stop-gap (if bug 006 isn't ready yet): use `} on Object catch (e) {
return Left(CacheFailure(e.toString())); }` as a safety net. Still leaks
toString, but at least catches all throwables.
