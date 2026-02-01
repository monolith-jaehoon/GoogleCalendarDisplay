import 'dart:math';

import 'package:flutter/widgets.dart';

class UiScale extends InheritedWidget {
  const UiScale({super.key, required this.scale, required super.child});

  final double scale;

  static double of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UiScale>();
    return scope?.scale ?? 1.0;
  }

  static double compute(Size size) {
    if (size.isEmpty) {
      return 1.0;
    }
    const baseWidth = 1920.0;
    const baseHeight = 1080.0;
    final raw = min(size.width / baseWidth, size.height / baseHeight);
    return raw.clamp(0.6, 1.4);
  }

  @override
  bool updateShouldNotify(UiScale oldWidget) => oldWidget.scale != scale;
}
