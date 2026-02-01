import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'package:google_calendar_display/app/platform.dart';
import 'package:google_calendar_display/app/ui_scale.dart';
import 'package:google_calendar_display/domain/app_config.dart';
import 'package:google_calendar_display/presentation/calendar_screen.dart';

class CalendarDisplayApp extends StatelessWidget {
  const CalendarDisplayApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.f11):
            const ToggleFullscreenIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ToggleFullscreenIntent: CallbackAction<ToggleFullscreenIntent>(
            onInvoke: (intent) async {
              if (isWeb || !isDesktop) {
                return null;
              }
              final isFull = await windowManager.isFullScreen();
              await windowManager.setFullScreen(!isFull);
              return null;
            },
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = UiScale.compute(constraints.biggest);
            return UiScale(
              scale: scale,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  brightness: Brightness.dark,
                  fontFamily: 'Spoqa Han Sans Neo',
                  scaffoldBackgroundColor: const Color(0xFF0B0F14),
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF4DD0E1),
                    secondary: Color(0xFF81C784),
                  ),
                  iconTheme: IconThemeData(size: 24 * scale),
                  textTheme: TextTheme(
                    headlineMedium: TextStyle(
                      fontSize: 64 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                    titleLarge: TextStyle(
                      fontSize: 48 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                    bodyLarge: TextStyle(fontSize: 32 * scale),
                    bodyMedium: TextStyle(fontSize: 28 * scale),
                  ),
                ),
                home: CalendarScreen(config: config),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ToggleFullscreenIntent extends Intent {
  const ToggleFullscreenIntent();
}
