import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';

/// A widget that displays a verification badge for sheikh users
class VerificationBadge extends StatelessWidget {
  /// Whether the user is a sheikh
  final bool isVerifiedSheikh;

  /// The size of the badge
  final double size;

  /// The color of the badge (defaults to a purple color)
  final Color? color;

  const VerificationBadge({
    Key? key,
    required this.isVerifiedSheikh,
    this.size = 16.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVerifiedSheikh) {
      return const SizedBox.shrink(); // Don't show anything if not a sheikh
    }

    return Container(
      margin: const EdgeInsets.only(left: 4.0),
      child: Icon(
        Icons.verified,
        size: size,
        color: color ?? AppStyles.lightPurple,
      ),
    );
  }
}

/// Extension on String to add a verification badge
extension VerificationBadgeRow on Widget {
  /// Adds a verification badge next to this widget if the user is a sheikh
  Widget addVerificationBadge(bool isVerifiedSheikh,
      {double size = 16.0, Color? color}) {
    if (!isVerifiedSheikh) {
      return this;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        this,
        VerificationBadge(
          isVerifiedSheikh: isVerifiedSheikh,
          size: size,
          color: color,
        ),
      ],
    );
  }
}
