import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A wrapper around AnimationController that safely handles negative elapsed times
/// to prevent the app from crashing when this issue occurs.
class SafeAnimationController extends AnimationController {
  /// Creates an animation controller that's safe from negative elapsed time errors.
  SafeAnimationController({
    double? value,
    Duration? duration,
    Duration? reverseDuration,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
    required TickerProvider vsync,
  }) : super(
          value: value,
          duration: duration,
          reverseDuration: reverseDuration,
          debugLabel: debugLabel,
          lowerBound: lowerBound,
          upperBound: upperBound,
          animationBehavior: animationBehavior,
          // Use our SafeTickerProvider wrapper around the original vsync
          vsync: _SafeTickerProvider(vsync),
        );

  /// Creates an unbounded animation controller that's safe from negative elapsed time errors.
  SafeAnimationController.unbounded({
    double value = 0.0,
    Duration? duration,
    Duration? reverseDuration,
    String? debugLabel,
    required TickerProvider vsync,
    AnimationBehavior animationBehavior = AnimationBehavior.preserve,
  }) : super.unbounded(
          value: value,
          duration: duration,
          reverseDuration: reverseDuration,
          debugLabel: debugLabel,
          // Use our SafeTickerProvider wrapper around the original vsync
          vsync: _SafeTickerProvider(vsync),
          animationBehavior: animationBehavior,
        );
}

/// A wrapper around TickerProvider that ensures elapsed time is never negative
class _SafeTickerProvider implements TickerProvider {
  final TickerProvider _delegate;

  _SafeTickerProvider(this._delegate);

  @override
  Ticker createTicker(TickerCallback onTick) {
    return _SafeTicker(
      (Duration elapsed) {
        // Only call onTick with non-negative elapsed durations
        if (elapsed.inMicroseconds < 0) {
          // Log warning in debug mode
          if (kDebugMode) {
            print(
                '⚠️ Prevented crash from negative elapsed time: ${elapsed.inMicroseconds / 1000000} seconds');
          }
          // Use a zero duration instead of the negative one to prevent the crash
          elapsed = Duration.zero;
        }

        // Call the original onTick with the sanitized elapsed duration
        onTick(elapsed);
      },
      _delegate,
    );
  }
}

/// A ticker that ensures it won't pass negative elapsed times to the callback
class _SafeTicker extends Ticker {
  _SafeTicker(TickerCallback onTick, TickerProvider creator)
      : super(onTick, debugLabel: 'SafeTicker created by $creator');
}

/// Helper function to create a SafeAnimationController instance
/// This makes it easy to replace AnimationController with SafeAnimationController throughout the app
AnimationController createSafeAnimationController({
  double? value,
  Duration? duration,
  Duration? reverseDuration,
  String? debugLabel,
  double lowerBound = 0.0,
  double upperBound = 1.0,
  AnimationBehavior animationBehavior = AnimationBehavior.normal,
  required TickerProvider vsync,
}) {
  return SafeAnimationController(
    value: value,
    duration: duration,
    reverseDuration: reverseDuration,
    debugLabel: debugLabel,
    lowerBound: lowerBound,
    upperBound: upperBound,
    animationBehavior: animationBehavior,
    vsync: vsync,
  );
}

/// Helper function to create an unbounded SafeAnimationController instance
AnimationController createUnboundedSafeAnimationController({
  double value = 0.0,
  Duration? duration,
  Duration? reverseDuration,
  String? debugLabel,
  AnimationBehavior animationBehavior = AnimationBehavior.preserve,
  required TickerProvider vsync,
}) {
  return SafeAnimationController.unbounded(
    value: value,
    duration: duration,
    reverseDuration: reverseDuration,
    debugLabel: debugLabel,
    animationBehavior: animationBehavior,
    vsync: vsync,
  );
}
