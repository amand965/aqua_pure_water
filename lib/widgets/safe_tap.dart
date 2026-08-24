import 'package:flutter/material.dart';

/// Global tap guard utility to prevent rapid double-tapping on buttons,
/// cards, navigation links, and database queries.
class SafeTap {
  static DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _defaultDebounceMs = 600;

  /// Returns true if the tap is allowed, or false if it is a duplicate rapid click.
  static bool canTap([int debounceMs = _defaultDebounceMs]) {
    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds < debounceMs) {
      return false;
    }
    _lastTapTime = now;
    return true;
  }

  /// Wraps a synchronous callback function so it only executes once within the debounce threshold.
  static VoidCallback? wrap(VoidCallback? action, [int debounceMs = _defaultDebounceMs]) {
    if (action == null) return null;
    return () {
      if (canTap(debounceMs)) {
        action();
      }
    };
  }
}
