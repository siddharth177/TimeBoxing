import 'dart:ui';

import 'package:flutter/cupertino.dart';

class StylusListener extends StatefulWidget {
  const StylusListener({
    super.key,
    required this.child,
    this.onStylusHover,
    this.onStylusContact,
  });

  final Widget child;
  final ValueChanged<Offset>? onStylusHover;
  final ValueChanged<Offset>? onStylusContact;

  @override
  State<StylusListener> createState() => _StylusListenerState();
}

class _StylusListenerState extends State<StylusListener> {
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: (event) {
        if (event.kind == PointerDeviceKind.stylus) {
          widget.onStylusHover?.call(event.localPosition);
        }
      },
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.stylus) {
          widget.onStylusContact?.call(event.localPosition);
        }
      },
      child: widget.child,
    );
  }
}

bool isStylus(PointerEvent event) =>
    event.kind == PointerDeviceKind.stylus ||
    event.kind == PointerDeviceKind.invertedStylus;
