import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeboxing/main.dart';

const _kLegacyKey = 'onboarding_seen';

String _uidKey(String uid) => 'onboarding_seen_$uid';

Future<void> markOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kLegacyKey, true);
  if (firebaseReady) {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) await prefs.setBool(_uidKey(uid), true);
    } catch (_) {}
  }
}

Future<bool> isOnboardingSeenForUser() async {
  if (!firebaseReady) {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLegacyKey) ?? false;
  }
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_uidKey(uid)) ?? false;
  } catch (_) {
    return false;
  }
}
