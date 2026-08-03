import 'package:flutter_riverpod/flutter_riverpod.dart';

final isLoginModeProvider = NotifierProvider<_IsLoginNotifier, bool>(
  _IsLoginNotifier.new,
);

class _IsLoginNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool v) => state = v;
}

final isForgotPasswordModeProvider = NotifierProvider<_IsForgotNotifier, bool>(
  _IsForgotNotifier.new,
);

class _IsForgotNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}
