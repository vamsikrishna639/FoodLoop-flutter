// The three layout sizes used across the app.
import 'package:flutter/widgets.dart';

enum ScreenSize { mobile, tablet, desktop }

abstract final class Breakpoints {
  static const double tablet = 600; // below this = mobile
  static const double desktop = 1024; // above this = desktop
  static const double maxContent = 1320; // widest the desktop layout grows

  static ScreenSize of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < tablet) return ScreenSize.mobile;
    if (w <= desktop) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  /// Horizontal page padding for the current size.
  static double gutter(BuildContext context) => switch (of(context)) {
        ScreenSize.mobile => 16,
        ScreenSize.tablet => 24,
        ScreenSize.desktop => 40,
      };
}

extension ScreenSizeX on BuildContext {
  ScreenSize get screen => Breakpoints.of(this);
  bool get isMobile => screen == ScreenSize.mobile;
  bool get isDesktop => screen == ScreenSize.desktop;
}
