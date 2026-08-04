import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:timeboxing/features/timeline/models/time_block.dart';
import 'package:timezone/timezone.dart' as tz;

class CalendarService {
  CalendarService._();

  static final CalendarService instance = CalendarService._();
  final _plugin = DeviceCalendarPlugin();

  static bool get _supported =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<bool> requestPermission() async {
    if (!_supported) return false;
    final result = await _plugin.requestPermissions();
    return result.data == true;
  }

  Future<String?> _writableCalendarId() async {
    final cals = await _plugin.retrieveCalendars();
    final writable = (cals.data ?? [])
        .where((c) => c.isReadonly == false)
        .toList();
    if (writable.isEmpty) return null;

    // Prefer Google account calendar - it syncs to Google Calendar app.
    final google = writable.firstWhere(
      (c) => c.accountType?.toLowerCase().contains('google') == true,
      orElse: () => writable.first,
    );
    return google.id;
  }

  Future<({String calendarId, String eventId})?> addBlock(
    TimeBlock block,
  ) async {
    if (!_supported) return null;
    if (!await requestPermission()) return null;

    final calId = await _writableCalendarId();
    if (calId == null) {
      return null;
    }

    final local = tz.local;
    final event = Event(
      calId,
      title: block.title,
      start: tz.TZDateTime.from(block.startTime, local),
      end: tz.TZDateTime.from(block.endTime, local),
    );
    final result = await _plugin.createOrUpdateEvent(event);
    final eventId = result?.data;
    if (eventId == null) return null;
    return (calendarId: calId, eventId: eventId);
  }

  Future<void> deleteBlock(String calendarId, String eventId) async {
    if (!_supported) return;
    await _plugin.deleteEvent(calendarId, eventId);
  }
}
