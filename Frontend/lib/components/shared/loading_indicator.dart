import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool center;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.center = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: AppStyles.txtFieldColor,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              fontFamily: 'Taha',
              color: AppStyles.txtFieldColor,
            ),
          ),
        ],
      ],
    );

    if (center) {
      return Center(child: content);
    }

    return content;
  }
}
