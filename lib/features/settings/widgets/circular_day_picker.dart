import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Circular 24-hour range picker with two draggable handles.
///
/// The ring is oriented with 12 PM (noon) at the top, so the typical
/// awake arc (≈ 6 AM → 10 PM) wraps over the top half of the circle.
class CircularDayPicker extends StatefulWidget {
  const CircularDayPicker({
    super.key,
    required this.startHour,
    required this.endHour,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final int startHour; // 0–23
  final int endHour; // 0–23, must be > startHour
  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;

  @override
  State<CircularDayPicker> createState() => _CircularDayPickerState();
}

enum _Handle { none, start, end }

class _CircularDayPickerState extends State<CircularDayPicker> {
  _Handle _dragging = _Handle.none;

  static const double _size = 260.0;

  // Noon (12h) at the top (12 o'clock = −π/2).
  // _h2a(0) = bottom, _h2a(6) = left, _h2a(12) = top, _h2a(18) = right.
  static double _h2a(num h) => (h / 24) * 2 * pi + pi / 2;

  // Inverse: angle → nearest whole hour 0–23
  static int _a2h(double a) {
    final norm = (a - pi / 2 + 4 * pi) % (2 * pi);
    return ((norm / (2 * pi)) * 24).round() % 24;
  }

  static Offset _a2p(double a, Offset c, double r) =>
      Offset(c.dx + r * cos(a), c.dy + r * sin(a));

  static Offset get _center => const Offset(_size / 2, _size / 2);

  static double get _r => _size / 2 * 0.68;

  void _onPanStart(DragStartDetails d) {
    final p = d.localPosition;
    final sp = _a2p(_h2a(widget.startHour), _center, _r);
    final ep = _a2p(_h2a(widget.endHour), _center, _r);
    const hit = 38.0;
    final ds = (p - sp).distance;
    final de = (p - ep).distance;
    if (ds < hit || de < hit) {
      setState(() => _dragging = ds <= de ? _Handle.start : _Handle.end);
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragging == _Handle.none) return;
    final raw = atan2(
      d.localPosition.dy - _center.dy,
      d.localPosition.dx - _center.dx,
    );

    if (_dragging == _Handle.start) {
      final h = _a2h(raw);
      final clamped = h.clamp(0, 12);
      if (clamped <= widget.endHour - 6) widget.onStartChanged(clamped);
    } else {
      // Compute end hour without % 24 so midnight resolves to 24, not 0.
      // Any result in [0, 11] means the drag crossed midnight — stop at 24.
      final norm = (raw - pi / 2 + 4 * pi) % (2 * pi);
      final hRaw = ((norm / (2 * pi)) * 24).round();
      final h = hRaw < 12 ? 24 : hRaw;
      final clamped = h.clamp(12, 24);
      if (clamped >= widget.startHour + 6) widget.onEndChanged(clamped);
    }
  }

  void _onPanEnd(DragEndDetails _) => setState(() => _dragging = _Handle.none);

  static String _fmt(int h) {
    if (h == 0 || h == 24) return '12 AM';
    if (h == 12) return '12 PM';
    if (h < 12) return '$h AM';
    return '${h - 12} PM';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox.square(
        dimension: _size,
        child: CustomPaint(
          painter: _RingPainter(
            startHour: widget.startHour,
            endHour: widget.endHour,
            scheme: scheme,
            active: _dragging,
          ),
          child: Center(
            child: _CenterLabel(
              startHour: widget.startHour,
              endHour: widget.endHour,
              fmt: _fmt,
              scheme: scheme,
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel({
    required this.startHour,
    required this.endHour,
    required this.fmt,
    required this.scheme,
  });

  final int startHour;
  final int endHour;
  final String Function(int) fmt;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final hours = endHour - startHour;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: AppColors.green60, label: fmt(startHour)),
        const SizedBox(height: 8),
        Text(
          '${hours}h',
          style: AppTextStyles.headingMd(color: scheme.onSurface),
        ),
        const SizedBox(height: 8),
        _Dot(color: AppColors.orange40, label: fmt(endHour)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: AppTextStyles.textSm()),
    ],
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.startHour,
    required this.endHour,
    required this.scheme,
    required this.active,
  });

  final int startHour;
  final int endHour;
  final ColorScheme scheme;
  final _Handle active;

  static double _h2a(num h) => (h / 24) * 2 * pi + pi / 2;

  static Offset _a2p(double a, Offset c, double r) =>
      Offset(c.dx + r * cos(a), c.dy + r * sin(a));

  static final _kTimeStops = <(double, Color)>[
    (0.0, AppColors.purple60), // 12 AM — deep night
    (4.0, AppColors.blue60), //  4 AM — pre-dawn
    (7.0, AppColors.orange20), //  7 AM — sunrise
    (10.0, AppColors.orange40), // 10 AM — morning
    (12.0, AppColors.yellow40), // 12 PM — noon peak
    (14.0, AppColors.orange40), //  2 PM — afternoon
    (17.0, AppColors.orange20), //  5 PM — late afternoon
    (19.0, AppColors.blue60), //  7 PM — dusk/sunset
    (21.0, AppColors.purple30), //  9 PM — evening
    (24.0, AppColors.purple60), // 12 AM — night
  ];

  static Color _colorAtHour(double h) {
    for (var i = 0; i < _kTimeStops.length - 1; i++) {
      final (h0, c0) = _kTimeStops[i];
      final (h1, c1) = _kTimeStops[i + 1];
      if (h >= h0 && h <= h1) {
        return Color.lerp(c0, c1, (h - h0) / (h1 - h0))!;
      }
    }
    return AppColors.gray80;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 * 0.68;
    const tw = 22.0;

    // ① Background (sleep) ring
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = scheme.surfaceContainerHighest
        ..style = PaintingStyle.stroke
        ..strokeWidth = tw,
    );

    // ② Active (awake) arc — stepped segments, each anchored to absolute time
    final sa = _h2a(startHour);
    var sweep = _h2a(endHour) - sa;
    if (sweep <= 0) sweep += 2 * pi;

    final arcRect = Rect.fromCircle(center: c, radius: r);
    const kSegments = 120;
    final dSweep = sweep / kSegments;
    final segPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = tw
      ..strokeCap = StrokeCap.butt;

    for (var i = 0; i < kSegments; i++) {
      final absoluteHour = startHour + (i / kSegments) * (endHour - startHour);
      segPaint.color = _colorAtHour(absoluteHour);
      // tiny overlap (+0.01) prevents hairline gaps between segments
      canvas.drawArc(arcRect, sa + i * dSweep, dSweep + 0.01, false, segPaint);
    }

    // ③ Tick marks inside the track at every 3 h
    for (var h = 0; h < 24; h += 3) {
      final a = _h2a(h);
      final isMajor = h % 6 == 0;
      canvas.drawLine(
        _a2p(a, c, r - tw / 2 + (isMajor ? 4.0 : 5.5)),
        _a2p(a, c, r + tw / 2 - (isMajor ? 4.0 : 5.5)),
        Paint()
          ..color = scheme.surface.withValues(alpha: isMajor ? 0.55 : 0.30)
          ..strokeWidth = isMajor ? 2.0 : 1.2,
      );
    }

    // ④ Labels at 6 AM / 12 PM / 6 PM / 12 AM outside the ring
    const labelH = [0, 6, 12, 18];
    const labelT = ['12 AM', '6 AM', '12 PM', '6 PM'];
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < 4; i++) {
      final a = _h2a(labelH[i]);
      final pos = _a2p(a, c, r + tw / 2 + 16);
      tp.text = TextSpan(
        text: labelT[i],
        style: TextStyle(
          fontSize: 9,
          color: scheme.onSurface.withValues(alpha: 0.38),
          fontWeight: FontWeight.w500,
        ),
      );
      tp.layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // ⑤ Handles
    _drawHandle(
      canvas,
      startHour,
      AppColors.green60,
      active == _Handle.start,
      c,
      r,
    );
    _drawHandle(
      canvas,
      endHour,
      AppColors.orange40,
      active == _Handle.end,
      c,
      r,
    );
  }

  void _drawHandle(
    Canvas canvas,
    int hour,
    Color color,
    bool pressed,
    Offset c,
    double r,
  ) {
    final pos = _a2p(_h2a(hour), c, r);

    canvas.drawCircle(
      pos,
      20,
      Paint()
        ..color = color.withValues(alpha: pressed ? 0.38 : 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawCircle(
      pos,
      13,
      Paint()..color = pressed ? color.withValues(alpha: 0.78) : color,
    );

    canvas.drawCircle(
      pos,
      13,
      Paint()
        ..color = AppColors.white.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.startHour != startHour ||
      old.endHour != endHour ||
      old.active != active;
}
