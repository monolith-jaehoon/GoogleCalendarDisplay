import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';

import 'package:google_calendar_display/app/app.dart';
import 'package:google_calendar_display/app/platform.dart';
import 'package:google_calendar_display/domain/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'ko_KR';
  await initializeDateFormatting('ko_KR');
  final config = await AppConfig.load();
  if (!isWeb && isDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(fullScreen: false, center: true),
    );
  }
  runApp(CalendarDisplayApp(config: config));
  if (!isWeb && isDesktop) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await windowManager.show();
      await windowManager.focus();
      if (config.startInFullscreen) {
        await windowManager.setFullScreen(true);
      }
    });
  }
}
