import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:google_calendar_display/data/auth_controller.dart';
import 'package:google_calendar_display/data/google_calendar_repository.dart';
import 'package:google_calendar_display/domain/app_config.dart';
import 'package:google_calendar_display/domain/calendar_event.dart';

class CalendarController extends ChangeNotifier {
  CalendarController({
    required this.config,
    required GoogleCalendarRepository calendarRepository,
    required AuthController authController,
  }) : _calendarRepository = calendarRepository,
       _authController = authController;

  final AppConfig config;
  final GoogleCalendarRepository _calendarRepository;
  final AuthController _authController;

  Timer? _clockTimer;
  Timer? _refreshTimer;
  DateTime _now = DateTime.now();
  Map<String, List<CalendarEvent>> _eventsByCalendar = {};
  String? _errorMessage;
  bool _loading = true;

  DateTime get now => _now;
  List<CalendarEvent> eventsFor(String calendarId) {
    return _eventsByCalendar[calendarId] ?? const [];
  }

  String? get errorMessage => _errorMessage;
  bool get loading => _loading;
  bool get isSignedIn => _authController.isSignedIn;
  String? get authErrorMessage => _authController.errorMessage;

  Future<void> init() async {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      notifyListeners();
    });
    _refreshTimer = Timer.periodic(
      Duration(minutes: max(1, config.refreshIntervalMinutes)),
      (_) => fetchAndParse(),
    );
    await _authController.init();
    if (isSignedIn) {
      await fetchAndParse(initial: true);
    } else {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(BuildContext context) async {
    await _authController.signIn(context);
    notifyListeners();
    if (isSignedIn) {
      await fetchAndParse(initial: true);
    } else {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAndParse({bool initial = false}) async {
    if (initial) {
      _loading = true;
      _errorMessage = null;
      notifyListeners();
    }

    final now = DateTime.now();
    final windowStart = now.subtract(Duration(minutes: config.pastMinutes));
    final windowEnd = now.add(Duration(minutes: config.futureMinutes));

    final client = _authController.client;
    if (client == null) {
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      if (config.calendars.isEmpty) {
        _loading = false;
        _errorMessage = '캘린더가 설정되어 있지 않습니다.';
        notifyListeners();
        return;
      }

      final updatedEvents = Map<String, List<CalendarEvent>>.from(
        _eventsByCalendar,
      );
      final errors = <String>[];

      for (final calendarConfig in config.calendars) {
        final calendarId = calendarConfig.googleCalendarId.trim();
        if (calendarId.isEmpty) {
          errors.add('${calendarConfig.roomName} 캘린더 ID가 비어 있습니다.');
          continue;
        }
        try {
          final events = await _calendarRepository.fetchEvents(
            client,
            calendarId,
            windowStart,
            windowEnd,
          );
          updatedEvents[calendarId] = events;
        } catch (error) {
          errors.add('${calendarConfig.roomName} 캘린더를 불러오지 못했습니다.');
        }
      }

      _eventsByCalendar = updatedEvents;
      _errorMessage = errors.isEmpty ? null : errors.join('\n');
    } catch (error) {
      _errorMessage = '캘린더를 불러오지 못했습니다. 마지막 데이터로 표시합니다.';
    }

    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _refreshTimer?.cancel();
    _authController.dispose();
    super.dispose();
  }
}
