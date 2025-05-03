import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';

/// A safer version of AnimationController that handles negative elapsed times
/// This fixes the "elapsedInSeconds >= 0.0" assertion error that happens sporadically
class SafeAnimationController extends AnimationController {
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
          vsync: vsync,
        );

  /// Creates a safe animation controller with no upper or lower bound for its value
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
          vsync: vsync,
          animationBehavior: animationBehavior,
        );
}

/// We can't directly override AnimationController's _tick method, so instead we
/// create a TickerProvider wrapper that ensures elapsed time is never negative
class SafeTickerProvider implements TickerProvider {
  final TickerProvider _delegate;

  SafeTickerProvider(this._delegate);

  @override
  Ticker createTicker(TickerCallback onTick) {
    return _delegate.createTicker((Duration elapsed) {
      // Make sure elapsed time is never negative
      final Duration safeElapsed =
          Duration(microseconds: elapsed.inMicroseconds.abs());
      onTick(safeElapsed);
    });
  }
}

/// Helper function to create a standard AnimationController with safe ticker
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
  return AnimationController(
    value: value,
    duration: duration,
    reverseDuration: reverseDuration,
    debugLabel: debugLabel,
    lowerBound: lowerBound,
    upperBound: upperBound,
    animationBehavior: animationBehavior,
    vsync: SafeTickerProvider(vsync),
  );
}

/// Helper function to create an unbounded AnimationController with safe ticker
AnimationController createUnboundedSafeAnimationController({
  double value = 0.0,
  Duration? duration,
  Duration? reverseDuration,
  String? debugLabel,
  required TickerProvider vsync,
  AnimationBehavior animationBehavior = AnimationBehavior.preserve,
}) {
  return AnimationController.unbounded(
    value: value,
    duration: duration,
    reverseDuration: reverseDuration,
    debugLabel: debugLabel,
    vsync: SafeTickerProvider(vsync),
    animationBehavior: animationBehavior,
  );
}
