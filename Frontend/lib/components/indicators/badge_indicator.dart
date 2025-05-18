import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';

class BadgeIndicator extends StatelessWidget {
  final int count;
  final Color color;
  final double size;
  final bool showZero;

  const BadgeIndicator({
    Key? key,
    required this.count,
    this.color = Colors.red,
    this.size = 16.0,
    this.showZero = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't show if count is 0 and showZero is false
    if (count == 0 && !showZero) {
      return const SizedBox.shrink();
    }

    return Container(
      width: count > 99 ? size * 1.5 : size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
      child: count > 0
          ? Text(
              count > 99 ? '99+' : count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.65,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

class ChatDotIndicator extends StatelessWidget {
  final bool isVisible;
  final Color color;
  final double size;

  const ChatDotIndicator({
    Key? key,
    required this.isVisible,
    this.color = Colors.redAccent,
    this.size = 10.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// A Stack wrapper that adds a badge to any widget
class BadgedWidget extends StatelessWidget {
  final Widget child;
  final int count;
  final double badgeSize;
  final Color badgeColor;
  final bool showZero;
  final Alignment badgeAlignment;

  const BadgedWidget({
    Key? key,
    required this.child,
    required this.count,
    this.badgeSize = 16.0,
    this.badgeColor = Colors.redAccent,
    this.showZero = false,
    this.badgeAlignment = Alignment.topRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        if (count > 0 || showZero)
          Positioned(
            top: badgeAlignment == Alignment.topRight ||
                    badgeAlignment == Alignment.topLeft
                ? -5
                : null,
            bottom: badgeAlignment == Alignment.bottomRight ||
                    badgeAlignment == Alignment.bottomLeft
                ? -5
                : null,
            right: badgeAlignment == Alignment.topRight ||
                    badgeAlignment == Alignment.bottomRight
                ? -5
                : null,
            left: badgeAlignment == Alignment.topLeft ||
                    badgeAlignment == Alignment.bottomLeft
                ? -5
                : null,
            child: BadgeIndicator(
              count: count,
              color: badgeColor,
              size: badgeSize,
              showZero: showZero,
            ),
          ),
      ],
    );
  }
}
