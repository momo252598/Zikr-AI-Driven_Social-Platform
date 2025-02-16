import 'package:flutter/material.dart';

class BackgroundImage extends StatelessWidget {
  const BackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://cdn.builder.io/api/v1/image/assets/11b408c8254a40c882d2b3146606194a/d954707c2d7fdfe01ce76d3b5329480361696ab3a57fe49c2cd23eb4b0810b34?apiKey=11b408c8254a40c882d2b3146606194a&',
      width: double.infinity,
      fit: BoxFit.contain,
    );
  }
}
