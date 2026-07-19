import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthService {
  static final _auth = FirebaseAuth.instance;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _isAppleNative =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        return await _auth.signInWithPopup(GoogleAuthProvider());
      }
      if (_isAndroid) {
        return await _auth.signInWithProvider(GoogleAuthProvider());
      }
      // iOS / macOS: native google_sign_in flow
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  static Future<UserCredential?> signInWithApple() async {
    try {
      if (kIsWeb) {
        final provider = OAuthProvider('apple.com')
          ..addScope('email')
          ..addScope('name');
        return await _auth.signInWithPopup(provider);
      }
      if (_isAndroid) {
        final provider = OAuthProvider('apple.com')
          ..addScope('email')
          ..addScope('name');
        return await _auth.signInWithProvider(provider);
      }
      // iOS / macOS: native Sign In with Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      return await _auth.signInWithCredential(oauthCredential);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  static bool get supportsApple =>
      kIsWeb || _isAppleNative || defaultTargetPlatform == TargetPlatform.iOS;
}
