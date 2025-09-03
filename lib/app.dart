import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'state/auth_providers.dart';
import 'screens/login_screen.dart';
import 'screens/timeline_screen.dart';

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure Intl has a default locale for formatting
    Intl.defaultLocale ??= 'en_US';

    final session = ref.watch(sessionProvider);

    return MaterialApp(
      title: 'CrimsonCrisis',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0095F6)),
        useMaterial3: true,
      ),
      home: switch (session) {
        AsyncData(value: final value) => value == null
            ? const LoginScreen()
            : const TimelineScreen(),
        AsyncError() => const LoginScreen(),
        _ => const _SplashScreen(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

