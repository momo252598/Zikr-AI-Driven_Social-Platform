import 'package:flutter/material.dart';

class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Quran App',
          style: TextStyle(
            color: Colors.black,
            fontSize: 43,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6),
        // Text(
        //   'Asalamu Alaikum !!!',
        //   style: TextStyle(
        //     color: Color(0xFF010001),
        //     fontSize: 14,
        //     fontFamily: 'Poppins',
        //     fontWeight: FontWeight.w700,
        //   ),
        // ),
      ],
    );
  }
}
