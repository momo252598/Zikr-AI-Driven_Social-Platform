import 'package:flutter/material.dart';
import 'package:software_graduation_project/base/res/styles/app_styles.dart';

class Basmallah extends StatefulWidget {
  int index;
  Basmallah({super.key, required this.index});

  @override
  State<Basmallah> createState() => _BasmallahState();
}

class _BasmallahState extends State<Basmallah> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return SizedBox(
      width: screenSize.width,
      child: Padding(
        padding: EdgeInsets.only(
            left: (screenSize.width * .2),
            right: (screenSize.width * .2),
            top: 8,
            bottom: 2),
        child: Image.asset(
          "assets/images/Basmala.png",
          color: AppStyles.black,
          width: MediaQuery.of(context).size.width * .4,
        ),
      ),
    );
  }
}
