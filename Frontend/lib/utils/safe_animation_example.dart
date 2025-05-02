import 'package:flutter/material.dart';
import 'safe_animation_controller.dart';

/// Example of how to use SafeAnimationController throughout your app
///
/// This shows both approaches:
/// 1. Direct usage of SafeAnimationController
/// 2. Using the helper functions (recommended)

class SafeAnimationExample extends StatefulWidget {
  const SafeAnimationExample({super.key});

  @override
  State<SafeAnimationExample> createState() => _SafeAnimationExampleState();
}

class _SafeAnimationExampleState extends State<SafeAnimationExample>
    with SingleTickerProviderStateMixin {
  // OPTION 1: Direct usage of SafeAnimationController
  // Replace "AnimationController" with "SafeAnimationController"
  late SafeAnimationController _directController;

  // OPTION 2: Using the helper function (recommended)
  // Keep the type as AnimationController, but initialize with the helper
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // OPTION 1: Direct usage
    _directController = SafeAnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // OPTION 2: Using helper function (recommended)
    _controller = createSafeAnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Then use the controller normally
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // You can use all AnimationController methods normally
    _controller.forward();
  }

  @override
  void dispose() {
    _directController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safe Animation Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Example using the animation
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: Container(
                    width: 200 * _animation.value + 50,
                    height: 200 * _animation.value + 50,
                    color: Colors.blue,
                    child: const Center(
                      child: Text(
                        'Safe Animation',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Example of toggling animation
                if (_controller.status == AnimationStatus.completed) {
                  _controller.reverse();
                } else {
                  _controller.forward();
                }
              },
              child: const Text('Toggle Animation'),
            ),
          ],
        ),
      ),
    );
  }
}
