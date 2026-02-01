import 'package:flutter/foundation.dart';

bool get isWeb => kIsWeb;

bool get isDesktop {
  return defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS;
}
