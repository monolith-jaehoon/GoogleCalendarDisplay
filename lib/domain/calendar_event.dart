class CalendarEvent {
  CalendarEvent({
    required this.title,
    required this.start,
    required this.end,
    required this.allDay,
    this.organizer,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final String? organizer;
}
