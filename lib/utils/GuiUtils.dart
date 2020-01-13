import 'dart:ui';

import 'package:flutter/material.dart';

class BlurFrame {
  /// to create a blur background for the bottom sheet
  static createBlurFrame({double blurAmount = 0.0, Color tintColorWithOpacity, Widget childThatWillGiveSize}) {
    Color backgroundTint = Colors.red;
    if (tintColorWithOpacity != null) {
      backgroundTint = tintColorWithOpacity;
    }

    return BackdropFilter(
      // to blur the background, if needed
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          decoration: BoxDecoration(color: backgroundTint),
          child: childThatWillGiveSize,
        ));
  }
}