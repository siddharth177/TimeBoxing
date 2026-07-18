import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox/core/router/app_router.dart';
import 'package:timebox/core/theme/app_theme.dart';
import 'package:timebox/features/settings/providers/settings_provider.dart';

class TimeBoxApp extends ConsumerWidget {
  const TimeBoxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'TimeBox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
