import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_bootstrap.dart';

/// Application entry point.
///
/// Synchronous: [WidgetsFlutterBinding.ensureInitialized] is called first
/// (it is synchronous) and then [runApp] is called immediately — no `await`
/// before [runApp]. The async work (SharedPreferences hydration) is delegated
/// to [AppBootstrap] which runs inside the widget tree.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AppBootstrap()));
}
