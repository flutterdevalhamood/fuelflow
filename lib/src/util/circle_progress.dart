import 'package:flutter/material.dart';

import '../BaseScreen.dart';

OverlayEntry circleOverlay = OverlayEntry(
  builder:
      (context) => Material(
        color: Colors.black26,
        child: const Center(child: CircularProgressIndicator.adaptive()),
      ),
);

showCircle() {
  navigatorKey?.currentState?.overlay?.insert(circleOverlay);
}

removeCircle() {
  if (circleOverlay.mounted) {
    circleOverlay.remove();
  }
}
