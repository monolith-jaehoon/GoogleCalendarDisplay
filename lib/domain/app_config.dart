import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class AppConfig {
  AppConfig({
    required this.calendars,
    required this.layout,
    required this.headerTitle,
    required this.displayCalendarIndices,
    required this.oauthWebClientId,
    required this.oauthAndroidClientId,
    required this.oauthDesktopClientId,
    required this.oauthDesktopClientSecret,
    required this.refreshIntervalMinutes,
    required this.timezone,
    required this.use24HourFormat,
    required this.pastMinutes,
    required this.futureMinutes,
    required this.startInFullscreen,
  });

  final List<CalendarConfig> calendars;
  final CalendarLayout layout;
  final String headerTitle;
  final List<int> displayCalendarIndices;
  final String oauthWebClientId;
  final String oauthAndroidClientId;
  final String oauthDesktopClientId;
  final String oauthDesktopClientSecret;
  final int refreshIntervalMinutes;
  final String timezone;
  final bool use24HourFormat;
  final int pastMinutes;
  final int futureMinutes;
  final bool startInFullscreen;

  List<CalendarConfig> get displayCalendars {
    if (layout == CalendarLayout.single) {
      if (calendars.isEmpty) {
        return [];
      }
      if (displayCalendarIndices.isNotEmpty) {
        final index = displayCalendarIndices.first;
        if (index >= 0 && index < calendars.length) {
          return [calendars[index]];
        }
      }
      return [calendars.first];
    }

    if (displayCalendarIndices.isNotEmpty) {
      final selected = <CalendarConfig>[];
      for (final index in displayCalendarIndices) {
        if (index < 0 || index >= calendars.length) {
          continue;
        }
        selected.add(calendars[index]);
      }
      return selected;
    }

    return calendars.take(3).toList();
  }

  static Future<AppConfig> load() async {
    final raw = await rootBundle.loadString('assets/config.yaml');
    final yaml = loadYaml(raw);
    final configMap = _yamlToMap(yaml);
    return AppConfig.fromMap(configMap);
  }

  static Map<String, dynamic> _yamlToMap(dynamic value) {
    final decoded = jsonDecode(jsonEncode(value));
    return (decoded as Map).cast<String, dynamic>();
  }

  factory AppConfig.fromMap(Map<String, dynamic> configMap) {
    final oauth = configMap['oauth'] as Map<String, dynamic>?;
    final rawCalendars = configMap['calendars'] as List<dynamic>?;
    final calendars =
        rawCalendars
            ?.whereType<Map<String, dynamic>>()
            .map(CalendarConfig.fromMap)
            .toList() ??
        _legacyCalendars(configMap);
    final layout = CalendarLayoutX.fromValue(configMap['layout'] as String?);
    final headerTitle = configMap['headerTitle'] as String? ?? '';
    final displayCalendarIndices =
        (configMap['displayCalendarIndices'] as List<dynamic>?)
            ?.map((value) => (value as num).toInt())
            .toList() ??
        const <int>[];

    return AppConfig(
      calendars: calendars,
      layout: layout,
      headerTitle: headerTitle,
      displayCalendarIndices: displayCalendarIndices,
      oauthWebClientId: oauth?['webClientId'] as String? ?? '',
      oauthAndroidClientId: oauth?['androidClientId'] as String? ?? '',
      oauthDesktopClientId: oauth?['desktopClientId'] as String? ?? '',
      oauthDesktopClientSecret: oauth?['desktopClientSecret'] as String? ?? '',
      refreshIntervalMinutes:
          (configMap['refreshIntervalMinutes'] as num?)?.toInt() ?? 1,
      timezone: configMap['timezone'] as String? ?? 'Asia/Seoul',
      use24HourFormat: configMap['use24HourFormat'] as bool? ?? false,
      pastMinutes: (configMap['pastMinutes'] as num?)?.toInt() ?? 60,
      futureMinutes: (configMap['futureMinutes'] as num?)?.toInt() ?? 180,
      startInFullscreen: configMap['startInFullscreen'] as bool? ?? true,
    );
  }

  static List<CalendarConfig> _legacyCalendars(Map<String, dynamic> configMap) {
    final roomName = configMap['roomName'] as String? ?? '일정';
    final googleCalendarId = configMap['googleCalendarId'] as String? ?? '';
    return [
      CalendarConfig(roomName: roomName, googleCalendarId: googleCalendarId),
    ];
  }
}

class CalendarConfig {
  const CalendarConfig({
    required this.roomName,
    required this.googleCalendarId,
  });

  final String roomName;
  final String googleCalendarId;

  factory CalendarConfig.fromMap(Map<String, dynamic> configMap) {
    return CalendarConfig(
      roomName: configMap['roomName'] as String? ?? '일정',
      googleCalendarId: configMap['googleCalendarId'] as String? ?? '',
    );
  }
}

enum CalendarLayout { single, tripleHorizontal, tripleVertical }

extension CalendarLayoutX on CalendarLayout {
  static CalendarLayout fromValue(String? value) {
    switch (value) {
      case 'tripleHorizontal':
      case 'triple_horizontal':
        return CalendarLayout.tripleHorizontal;
      case 'tripleVertical':
      case 'triple_vertical':
        return CalendarLayout.tripleVertical;
      case 'single':
      default:
        return CalendarLayout.single;
    }
  }
}
