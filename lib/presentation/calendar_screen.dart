import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:google_calendar_display/app/ui_scale.dart';
import 'package:google_calendar_display/data/auth_controller.dart';
import 'package:google_calendar_display/data/google_calendar_repository.dart';
import 'package:google_calendar_display/domain/app_config.dart';
import 'package:google_calendar_display/domain/calendar_event.dart';
import 'package:google_calendar_display/presentation/calendar_controller.dart';
import 'package:google_calendar_display/presentation/timeline_view.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.config});

  final AppConfig config;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CalendarController(
      config: widget.config,
      calendarRepository: GoogleCalendarRepository(),
      authController: AuthController(widget.config),
    );
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = UiScale.of(context);
        final timeFormat = DateFormat(
          widget.config.use24HourFormat ? 'HH:mm' : 'a h:mm',
          'ko_KR',
        );

        if (!_controller.isSignedIn) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24 * scale),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 48 * scale),
                    SizedBox(height: 16 * scale),
                    Text(
                      'Google 계정 로그인이 필요합니다.',
                      style: TextStyle(fontSize: 18 * scale),
                    ),
                    SizedBox(height: 12 * scale),
                    if (_controller.authErrorMessage != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12 * scale),
                        child: Text(
                          _controller.authErrorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => _controller.signIn(context),
                      icon: const Icon(Icons.login),
                      label: const Text('Google 로그인'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  roomName: _headerTitle(),
                  timeText: timeFormat.format(_controller.now),
                  loading: _controller.loading,
                  errorMessage: _controller.errorMessage,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16 * scale,
                      8 * scale,
                      16 * scale,
                      16 * scale,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        DateTime displayStart;
                        DateTime displayEnd;
                        displayStart = _controller.now.subtract(
                          Duration(minutes: widget.config.pastMinutes),
                        );
                        displayEnd = _controller.now.add(
                          Duration(minutes: widget.config.futureMinutes),
                        );

                        List<CalendarEvent> visibleEvents(
                          CalendarConfig calendar,
                        ) {
                          final events = _controller.eventsFor(
                            calendar.googleCalendarId,
                          );
                          return events
                              .where(
                                (event) =>
                                    event.end.isAfter(displayStart) &&
                                    event.start.isBefore(displayEnd),
                              )
                              .toList()
                            ..sort((a, b) => a.start.compareTo(b.start));
                        }

                        final calendars = widget.config.displayCalendars;

                        if (widget.config.layout == CalendarLayout.single) {
                          if (calendars.isEmpty) {
                            return const Center(child: Text('표시할 캘린더가 없습니다.'));
                          }
                          final calendar = calendars.first;
                          return TimelineView(
                            now: _controller.now,
                            rangeStart: displayStart,
                            rangeEnd: displayEnd,
                            events: visibleEvents(calendar),
                            use12HourFormat: !widget.config.use24HourFormat,
                          );
                        }

                        if (widget.config.layout ==
                            CalendarLayout.tripleHorizontal) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final calendar in calendars)
                                Expanded(
                                  child: _CalendarPane(
                                    roomName: calendar.roomName,
                                    now: _controller.now,
                                    rangeStart: displayStart,
                                    rangeEnd: displayEnd,
                                    events: visibleEvents(calendar),
                                    use12HourFormat:
                                        !widget.config.use24HourFormat,
                                  ),
                                ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            for (final calendar in calendars)
                              Expanded(
                                child: _CalendarPane(
                                  roomName: calendar.roomName,
                                  now: _controller.now,
                                  rangeStart: displayStart,
                                  rangeEnd: displayEnd,
                                  events: visibleEvents(calendar),
                                  use12HourFormat:
                                      !widget.config.use24HourFormat,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _headerTitle() {
    final customTitle = widget.config.headerTitle.trim();
    if (customTitle.isNotEmpty) {
      return customTitle;
    }
    if (widget.config.layout == CalendarLayout.single) {
      final calendars = widget.config.displayCalendars;
      if (calendars.isEmpty) {
        return '일정';
      }
      return calendars.first.roomName;
    }
    return '캘린더 일정';
  }
}

class _CalendarPane extends StatelessWidget {
  const _CalendarPane({
    required this.roomName,
    required this.now,
    required this.rangeStart,
    required this.rangeEnd,
    required this.events,
    required this.use12HourFormat,
  });

  final String roomName;
  final DateTime now;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final List<CalendarEvent> events;
  final bool use12HourFormat;

  @override
  Widget build(BuildContext context) {
    final scale = UiScale.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1B2530)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 8 * scale,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1B2530), width: 1),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                roomName,
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8 * scale),
              child: TimelineView(
                now: now,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd,
                events: events,
                use12HourFormat: use12HourFormat,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.roomName,
    required this.timeText,
    required this.loading,
    required this.errorMessage,
  });

  final String roomName;
  final String timeText;
  final bool loading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final scale = UiScale.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1B2530), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(top: 4 * scale),
                    child: Text(
                      errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeText, style: Theme.of(context).textTheme.headlineMedium),
              if (loading)
                Padding(
                  padding: EdgeInsets.only(top: 4 * scale),
                  child: Text(
                    '캘린더 업데이트 중...',
                    style: TextStyle(fontSize: 24 * scale),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
