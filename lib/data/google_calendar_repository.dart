import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

import 'package:google_calendar_display/domain/calendar_event.dart';

class GoogleCalendarRepository {
  Future<List<CalendarEvent>> fetchEvents(
    auth.AuthClient client,
    String calendarId,
    DateTime windowStart,
    DateTime windowEnd,
  ) async {
    final api = calendar.CalendarApi(client);
    final events = <CalendarEvent>[];
    String? pageToken;

    do {
      final response = await api.events.list(
        calendarId,
        timeMin: windowStart.toUtc(),
        timeMax: windowEnd.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 2500,
        pageToken: pageToken,
      );
      for (final item in response.items ?? <calendar.Event>[]) {
        if (item.status == 'cancelled') {
          continue;
        }
        final converted = _toCalendarEvent(item);
        if (converted != null) {
          events.add(converted);
        }
      }
      pageToken = response.nextPageToken;
    } while (pageToken != null);

    return events;
  }

  CalendarEvent? _toCalendarEvent(calendar.Event event) {
    final summary = event.summary ?? '';
    final organizer =
        event.organizer?.displayName ??
        event.organizer?.email ??
        event.creator?.displayName ??
        event.creator?.email;
    final startInfo = event.start;
    final endInfo = event.end;
    if (startInfo == null) {
      return null;
    }

    if (startInfo.date != null) {
      final startDate = startInfo.date!;
      final endDate = endInfo?.date ?? startDate.add(const Duration(days: 1));
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      return CalendarEvent(
        title: summary,
        start: start,
        end: end.isAfter(start) ? end : start.add(const Duration(days: 1)),
        allDay: true,
        organizer: organizer,
      );
    }

    final startDateTime = startInfo.dateTime;
    if (startDateTime == null) {
      return null;
    }
    final endDateTime =
        endInfo?.dateTime ?? startDateTime.add(const Duration(hours: 1));

    final start = startDateTime.isUtc ? startDateTime.toLocal() : startDateTime;
    final end = endDateTime.isUtc ? endDateTime.toLocal() : endDateTime;

    return CalendarEvent(
      title: summary,
      start: start,
      end: end.isAfter(start) ? end : start.add(const Duration(hours: 1)),
      allDay: false,
      organizer: organizer,
    );
  }
}
