import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timeboxing/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz_lib;
import 'app.dart';
import 'firebase_options.dart';
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
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidPlayIntegrityProvider(),
      providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
      // TODO: replace 'recaptcha_secret_key' with your reCAPTCHA v3 site key from Google Cloud Console
      providerWeb: ReCaptchaV3Provider('reCAPTCHA'),
    );

    firebaseReady = true;
  } catch (e) {
    debugPrint(
      '[TimeBox] Firebase not configured — running in demo mode. ($e)',
    );
  }

  tz.initializeTimeZones();
  try {
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz_lib.setLocalLocation(tz_lib.getLocation(localTz.identifier));
  } catch (_) {
    tz_lib.setLocalLocation(tz_lib.UTC);
  }

  await NotificationService.init();

  runApp(const ProviderScope(child: TimeBoxApp()));
}
