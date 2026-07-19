import 'package:flutter_riverpod/flutter_riverpod.dart';

final isLoginModeProvider = StateProvider<bool>((ref) => true);
final isForgotPasswordModeProvider = StateProvider<bool>((ref) => false);