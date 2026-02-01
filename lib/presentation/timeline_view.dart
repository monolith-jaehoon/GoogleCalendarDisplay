import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:google_calendar_display/app/ui_scale.dart';
import 'package:google_calendar_display/domain/calendar_event.dart';

class TimelineView extends StatelessWidget {
  const TimelineView({
    super.key,
    required this.now,
    required this.rangeStart,
    required this.rangeEnd,
    required this.events,
    required this.use12HourFormat,
  });

  final DateTime now;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final List<CalendarEvent> events;
  final bool use12HourFormat;

  Color _colorForTitle(String title) {
    if (title.trim().isEmpty) {
      return Colors.blueGrey;
    }
    const palette = [
      Color(0xFF42A5F5),
      Color(0xFF26A69A),
      Color(0xFF7E57C2),
      Color(0xFFEF5350),
      Color(0xFFFFA726),
      Color(0xFF66BB6A),
      Color(0xFF26C6DA),
      Color(0xFFAB47BC),
    ];
    var hash = 0;
    for (final unit in title.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final scale = UiScale.of(context);
    final double labelWidth = 140 * scale;
    final double horizontalPadding = 8 * scale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;
        final rangeMinutes = rangeEnd
            .difference(rangeStart)
            .inMinutes
            .toDouble();
        final format = DateFormat(
          use12HourFormat ? 'a h:mm' : 'HH:mm',
          'ko_KR',
        );

        double timeToY(DateTime time, {bool clamp = true}) {
          final minutes = time.difference(rangeStart).inMinutes.toDouble();
          final ratio = minutes / rangeMinutes;
          final value = ratio * height;
          if (!clamp) {
            return value;
          }
          return ratio.clamp(0.0, 1.0) * height;
        }

        return ClipRect(
          child: Stack(
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: TimelineGridPainter(
                  rangeStart: rangeStart,
                  rangeEnd: rangeEnd,
                  labelWidth: labelWidth,
                  labelStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  use12HourFormat: use12HourFormat,
                ),
              ),
              ...events.expand((event) {
                final double overflowTopPadding = 80.0 * scale;
                final fullTop = timeToY(event.start, clamp: false);
                final fullBottom = timeToY(event.end, clamp: false);
                final double eventHeight = max(
                  24.0 * scale,
                  fullBottom - fullTop,
                );
                final hiddenTopBox = max(0.0, -fullTop);
                final timeLabel = event.allDay
                    ? '종일'
                    : '${format.format(event.start)} - ${format.format(event.end)}';
                final baseColor = _colorForTitle(event.title);

                Widget buildBox() {
                  return Positioned(
                    left: labelWidth + horizontalPadding,
                    right: horizontalPadding,
                    top: fullTop,
                    height: eventHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: baseColor.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: baseColor.withOpacity(0.9)),
                      ),
                    ),
                  );
                }

                Widget buildText() {
                  return Positioned(
                    left: labelWidth + horizontalPadding,
                    right: horizontalPadding,
                    top: fullTop - overflowTopPadding,
                    height: eventHeight + overflowTopPadding,
                    child: LayoutBuilder(
                      builder: (context, eventConstraints) {
                        final double paddingTop = 8.0 * scale;
                        final double paddingBottom = 2.0 * scale;
                        final double paddingHorizontal = 8.0 * scale;
                        final padding = EdgeInsets.only(
                          top: paddingTop,
                          bottom: paddingBottom,
                          left: paddingHorizontal,
                          right: paddingHorizontal,
                        );
                        final availableHeight = max(
                          0.0,
                          eventHeight - hiddenTopBox - padding.vertical,
                        );
                        final bool hasOrganizer =
                            event.organizer != null &&
                            event.organizer!.trim().isNotEmpty;
                        final organizerText = hasOrganizer
                            ? event.organizer!.trim()
                            : '';
                        final titleText = event.title.isEmpty
                            ? '(제목 없음)'
                            : event.title;
                        final bool compact = availableHeight < 32 * scale;
                        final double baseTitleFontSize = 28 * scale;
                        final double baseMetaFontSize = 22 * scale;
                        final double baseSpacing = 6.0 * scale;
                        final textMaxWidth = max(
                          0.0,
                          eventConstraints.maxWidth - padding.horizontal,
                        );
                        final titlePainter = TextPainter(
                          text: TextSpan(
                            text: titleText,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: baseTitleFontSize,
                            ),
                          ),
                          textDirection: ui.TextDirection.ltr,
                          maxLines: compact ? 1 : 2,
                        )..layout(maxWidth: textMaxWidth);
                        final timePainter = TextPainter(
                          text: TextSpan(
                            text: timeLabel,
                            style: TextStyle(fontSize: baseMetaFontSize),
                          ),
                          textDirection: ui.TextDirection.ltr,
                          maxLines: 1,
                        )..layout(maxWidth: textMaxWidth);
                        final organizerPainter = hasOrganizer
                            ? (TextPainter(
                                text: TextSpan(
                                  text: organizerText,
                                  style: TextStyle(fontSize: baseMetaFontSize),
                                ),
                                textDirection: ui.TextDirection.ltr,
                                maxLines: 1,
                              )..layout(maxWidth: textMaxWidth))
                            : null;
                        final double textBlockHeight = hasOrganizer
                            ? titlePainter.height +
                                  baseSpacing +
                                  timePainter.height +
                                  baseSpacing +
                                  organizerPainter!.height
                            : titlePainter.height +
                                  baseSpacing +
                                  timePainter.height;
                        final maxOffset = max(
                          0.0,
                          eventHeight - textBlockHeight - padding.vertical,
                        );
                        final canFloat =
                            !compact &&
                            textBlockHeight <= (eventHeight - padding.vertical);
                        final baseTop = fullTop + paddingTop;
                        final maxTop = fullTop + paddingTop + maxOffset;
                        double desiredTop = baseTop;
                        if (canFloat && baseTop < padding.top) {
                          desiredTop = maxTop >= padding.top
                              ? padding.top
                              : maxTop;
                        }
                        final contentOffset = desiredTop - baseTop;
                        final contentPadding = padding.copyWith(
                          top: padding.top + contentOffset + overflowTopPadding,
                        );
                        final availableContentHeight = max(
                          0.0,
                          eventHeight +
                              overflowTopPadding -
                              contentOffset -
                              padding.vertical,
                        );
                        return ClipRect(
                          child: Padding(
                            padding: contentPadding,
                            child: SizedBox(
                              height: availableContentHeight,
                              width: double.infinity,
                              child: ClipRect(
                                child: Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    if (compact)
                                      Text(
                                        hasOrganizer
                                            ? '$titleText · $timeLabel · $organizerText'
                                            : '$titleText · $timeLabel',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: max(
                                            12.0 * scale,
                                            min(
                                              22.0 * scale,
                                              availableHeight * 0.9,
                                            ),
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    else
                                      Builder(
                                        builder: (context) {
                                          final fitScale = min(
                                            1.0,
                                            availableHeight <= 0
                                                ? 1.0
                                                : availableHeight /
                                                      textBlockHeight,
                                          );
                                          final titleStyle = TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: max(
                                              12.0 * scale,
                                              baseTitleFontSize * fitScale,
                                            ),
                                          );
                                          final metaStyle = TextStyle(
                                            fontSize: max(
                                              10.0 * scale,
                                              baseMetaFontSize * fitScale,
                                            ),
                                          );
                                          final spacing =
                                              baseSpacing * fitScale;
                                          return FittedBox(
                                            alignment: Alignment.topLeft,
                                            fit: BoxFit.scaleDown,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxWidth: textMaxWidth,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    titleText,
                                                    style: titleStyle,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: spacing),
                                                  Text(
                                                    timeLabel,
                                                    style: metaStyle,
                                                  ),
                                                  if (hasOrganizer) ...[
                                                    SizedBox(height: spacing),
                                                    Text(
                                                      organizerText,
                                                      style: metaStyle,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                return [buildBox(), buildText()];
              }),
              Positioned(
                left: labelWidth + horizontalPadding,
                right: horizontalPadding,
                top: timeToY(now),
                child: Container(height: 2 * scale, color: Colors.redAccent),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TimelineGridPainter extends CustomPainter {
  TimelineGridPainter({
    required this.rangeStart,
    required this.rangeEnd,
    required this.labelWidth,
    required this.labelStyle,
    required this.use12HourFormat,
  });

  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double labelWidth;
  final TextStyle? labelStyle;
  final bool use12HourFormat;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF233040)
      ..strokeWidth = 1;
    final dashedPaint = Paint()
      ..color = const Color(0xFF1A232F)
      ..strokeWidth = 1;

    final totalMinutes = rangeEnd.difference(rangeStart).inMinutes.toDouble();
    final format = DateFormat(use12HourFormat ? 'a h' : 'HH:mm', 'ko_KR');

    DateTime tick = _floorToHalfHour(rangeStart);
    while (tick.isBefore(rangeEnd) || tick.isAtSameMomentAs(rangeEnd)) {
      final minutes = tick.difference(rangeStart).inMinutes.toDouble();
      final y = (minutes / totalMinutes) * size.height;
      final isHour = tick.minute == 0;
      if (y < 0 || y > size.height) {
        tick = tick.add(const Duration(minutes: 30));
        continue;
      }
      if (isHour) {
        canvas.drawLine(
          Offset(labelWidth, y),
          Offset(size.width, y),
          linePaint,
        );
      } else {
        _drawDashedLine(
          canvas,
          Offset(labelWidth, y),
          Offset(size.width, y),
          paint: dashedPaint,
        );
      }

      if (isHour && y >= 8 && y <= size.height - 8) {
        final textPainter = TextPainter(
          text: TextSpan(text: format.format(tick), style: labelStyle),
          textDirection: ui.TextDirection.ltr,
        )..layout(maxWidth: labelWidth - 8);

        textPainter.paint(canvas, Offset(8, y - 8));
      }

      tick = tick.add(const Duration(minutes: 30));
    }
  }

  DateTime _floorToHalfHour(DateTime time) {
    final minute = time.minute < 30 ? 0 : 30;
    return DateTime(time.year, time.month, time.day, time.hour, minute);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end, {
    required Paint paint,
  }) {
    const double dashWidth = 6;
    const double dashSpace = 4;
    double x = start.dx;
    while (x < end.dx) {
      final nextX = min(x + dashWidth, end.dx);
      canvas.drawLine(Offset(x, start.dy), Offset(nextX, start.dy), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant TimelineGridPainter oldDelegate) {
    return oldDelegate.rangeStart != rangeStart ||
        oldDelegate.rangeEnd != rangeEnd ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.use12HourFormat != use12HourFormat;
  }
}
