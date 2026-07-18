import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timebox/main.dart' show firebaseReady;

final authStateProvider = StreamProvider<User?>((ref) {
  if (!firebaseReady) return Stream.value(null);
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});