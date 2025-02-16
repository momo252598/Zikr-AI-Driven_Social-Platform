import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '05:45',
          style: TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Image.network(
              'https://cdn.builder.io/api/v1/image/assets/11b408c8254a40c882d2b3146606194a/e39bae47c0e8f803f33bf4865724889f48131a15d58b4e77f00a8d0ed8d4ac61?apiKey=11b408c8254a40c882d2b3146606194a&',
              width: 12,
              height: 13,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 7),
            Image.network(
              'https://cdn.builder.io/api/v1/image/assets/11b408c8254a40c882d2b3146606194a/4aa67eebc9721d06b2420180ef18c98213366fc9234b29661615acd2b2b04bfb?apiKey=11b408c8254a40c882d2b3146606194a&',
              width: 19,
              height: 10,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ],
    );
  }
}
