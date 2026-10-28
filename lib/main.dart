import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yanzee_app/core/storage/token_storage.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenStorage.init();
  runApp(
    ProviderScope(
      retry: (retryCount, error) => null, // never retry, show errors at once
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'YanZee',
      routerConfig: appRouter,
      // Caps the phone's font-size setting once for the whole app, so text
      // never gets too big or too small on any phone.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.15,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}