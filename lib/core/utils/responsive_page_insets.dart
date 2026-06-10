import 'package:flutter/material.dart';

class ResponsivePageInsets {
  const ResponsivePageInsets._();

  static bool isTabletLandscape(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    return mediaQuery.orientation == Orientation.landscape &&
        size.width >= 800 &&
        size.height >= 480;
  }

  static EdgeInsets horizontal(
    BuildContext context, {
    double maxContentWidth = 900,
    double minMargin = 32,
  }) {
    if (!isTabletLandscape(context)) return EdgeInsets.zero;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final margin = ((screenWidth - maxContentWidth) / 2).clamp(
      minMargin,
      screenWidth / 2,
    );
    return EdgeInsets.symmetric(horizontal: margin);
  }

  static EdgeInsets content(
    BuildContext context, {
    double maxContentWidth = 900,
    double minMargin = 32,
    double horizontal = 16,
    double top = 0,
    double bottom = 0,
  }) {
    final margin = isTabletLandscape(context)
        ? (((MediaQuery.sizeOf(context).width - maxContentWidth) / 2) -
                horizontal)
            .clamp(
            minMargin,
            MediaQuery.sizeOf(context).width / 2,
          )
        : 0.0;

    return EdgeInsets.fromLTRB(
      horizontal + margin,
      top,
      horizontal + margin,
      bottom,
    );
  }
}
