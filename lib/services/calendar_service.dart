import 'package:device_calendar/device_calendar.dart';
import 'package:timeboxing/features/timeline/models/time_block.dart';
import 'package:timezone/timezone.dart' as tz;

class CalendarService {
  final _plugin = DeviceCalendarPlugin();

  Future<bool> requestPermission() async {
    final result = await _plugin.requestPermissions();
    return result.data == true;
  }

  Future<String?> _writableCalendarId() async {
    final cals = await _plugin.retrieveCalendars();
    final cal = cals.data?.firstWhere(
      (c) => c.isReadOnly == false,
      orElse: () => throw Exception('No writable calendar'),
    );
    return cal?.id;
  }

  Future<String?> addBlock(TimeBlock block) async {
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
    return result?.data;
  }

  Future<void> deleteBlock(String calendarId, String eventId) async {
    await _plugin.deleteEvent(calendarId, eventId);
  }
}
