import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timeboxing/services/notification_service.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool firebaseReady = false;
bool onboardingSeen = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
        // TODO: replace 'recaptcha_secret_key' with your reCAPTCHA v3 site key from Google Cloud Console
        webProvider: ReCaptchaV3Provider('recaptcha_secret_key'),
      );
    }
    firebaseReady = true;
  } catch (e) {
    debugPrint('[TimeBox] Firebase not configured — running in demo mode. ($e)');
  }

  await NotificationService.init();

  runApp(const ProviderScope(child: TimeBoxApp()));
}