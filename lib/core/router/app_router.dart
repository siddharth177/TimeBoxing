import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../main.dart';
import '../navigation/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/onboarding',
  redirect: (context, state) {
    final loc = state.matchedLocation;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return loc.startsWith('/auth') ? null : '/auth';
      if (!user.emailVerified) return '/verify-email';
      if (!onboardingSeen) return loc == '/onboarding' ? null : '/onboarding';
      return loc == '/home' ? null : '/home';
    } catch (_) {
      return '/home';
    }
  },
  refreshListenable: _AuthNotifier(),
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const EmailVerificationScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const AppShell(),
    ),
  ],
);

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    if (firebaseReady) {
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          // ignore: library_private_types_in_public_api
          onboardingSeen = prefs.getBool('onboarding_seen_${user.uid}') ?? false;
        } else {
          onboardingSeen = false;
        }
        notifyListeners();
      });
    }
  }
}
