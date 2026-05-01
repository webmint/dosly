# Bug 013: `main()` blocks on async work before `runApp` (no splash)

**Status**: Open
**Severity**: Warning
**Source**: audit (audits/2026-04-30-audit.md)
**Reported**: 2026-04-30
**Fixed**:

## Description

Constitution §4.2.1 [enforced]: "Never block `main()` on async work. Show a
splash, run async setup, then `runApp`."

`lib/main.dart` awaits `SharedPreferencesWithCache.create(...)` before calling
`runApp`. While SharedPreferences hydration is fast on modern devices, a
corrupted or platform-channel-stalled prefs file produces a frozen black
launch screen with no UI and no diagnostics.

## File(s)

| File | Detail |
|------|--------|
| lib/main.dart | Lines 8–19 (`main()` body) |

## Evidence

`lib/main.dart:8–19`:
```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: <String>{
        'themeMode',
        'useSystemTheme',
        'useSystemLanguage',
        'manualLanguage',
      },
    ),
  );
  runApp(
```

Reported by audit (security-reviewer F2).

## Fix Notes

Suggested approach (to be confirmed in `/fix`):

1. Rewrite `main` to call `runApp` immediately with a splash widget.
2. Hydrate SharedPreferences inside an async initializer (a `FutureProvider`
   or top-level `AsyncNotifier`) that gates the real UI on `AsyncValue.data`.
3. While the prefs hydrate, render a Material splash that matches the OS
   LaunchScreen (uses `Theme.of(context).colorScheme.surface` so the visual
   transition is seamless).
4. Add an `error` branch that surfaces a "could not load preferences" message
   with a "retry" action — covers the corrupted-prefs failure mode.

Pairs with bug 004 (codegen) — if `sharedPreferencesProvider` is migrated to
`@riverpod` first, the async initializer pattern is the natural shape.
