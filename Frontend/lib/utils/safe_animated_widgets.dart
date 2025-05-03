import 'package:flutter/material.dart';
import 'safe_animation_controller.dart';

/// A wrapper around Flutter's AnimatedBuilder that uses SafeAnimationController
class SafeAnimatedBuilder extends StatefulWidget {
  /// The child widget to pass to the AnimatedBuilder
  final Widget? child;

  /// The duration of the animation
  final Duration duration;

  /// The builder function that takes animation value and child
  final Widget Function(
      BuildContext context, Animation<double> animation, Widget? child) builder;

  /// Optional start value, defaults to 0.0
  final double? from;

  /// Optional end value, defaults to 1.0
  final double? to;

  /// Whether to auto-start the animation
  final bool autoStart;

  /// Optional curve for the animation
  final Curve curve;

  /// Create a SafeAnimatedBuilder
  const SafeAnimatedBuilder({
    Key? key,
    required this.duration,
    required this.builder,
    this.child,
    this.from,
    this.to,
    this.autoStart = true,
    this.curve = Curves.linear,
  }) : super(key: key);

  @override
  SafeAnimatedBuilderState createState() => SafeAnimatedBuilderState();
}

class SafeAnimatedBuilderState extends State<SafeAnimatedBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Use our safe animation controller
    _controller = createSafeAnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: widget.from ?? 0.0,
      upperBound: widget.to ?? 1.0,
    );

    // Create the animation with the specified curve
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

    // Auto start if needed
    if (widget.autoStart) {
      _controller.forward();
    }
  }

  /// Start the animation from the beginning
  void forward({double? from}) {
    if (from != null) {
      _controller.value = from;
    } else {
      _controller.reset();
    }
    _controller.forward();
  }

  /// Reset the animation to the start value
  void reset() {
    _controller.reset();
  }

  /// Stop the animation at current value
  void stop() {
    _controller.stop();
  }

  /// Reverse the animation
  void reverse({double? from}) {
    _controller.reverse(from: from);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => widget.builder(context, _animation, child),
      child: widget.child,
    );
  }
}

/// A fade animation widget that uses SafeAnimationController
class SafeFadeTransition extends StatefulWidget {
  /// The child widget to animate
  final Widget child;

  /// Animation duration
  final Duration duration;

  /// Whether the widget starts visible (true) or invisible (false)
  final bool initiallyVisible;

  /// Animation curve
  final Curve curve;

  const SafeFadeTransition({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.initiallyVisible = true,
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  SafeFadeTransitionState createState() => SafeFadeTransitionState();
}

class SafeFadeTransitionState extends State<SafeFadeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Use safe animation controller
    _controller = createSafeAnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

    // Set initial value based on initiallyVisible parameter
    if (widget.initiallyVisible) {
      _controller.value = 1.0;
    }
  }

  /// Show the widget (animate to fully visible)
  Future<void> show() async {
    await _controller.forward();
  }

  /// Hide the widget (animate to fully transparent)
  Future<void> hide() async {
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
