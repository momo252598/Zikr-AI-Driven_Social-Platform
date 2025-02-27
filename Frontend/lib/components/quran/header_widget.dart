import 'package:flutter/material.dart';
import 'package:quran/quran.dart';

class HeaderWidget extends StatelessWidget {
  final dynamic e;
  final dynamic jsonData;
  final bool isWeb;

  const HeaderWidget({
    Key? key,
    required this.e,
    required this.jsonData,
    this.isWeb = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For web display, use a fixed width or responsive width based on container
    final width = isWeb
        ? MediaQuery.of(context).size.width *
            0.65 // 65% of available width for web
        : MediaQuery.of(context).size.width; // Full width for mobile

    // Increase text size for web from 0.8 to 1.5 (much larger)
    final double textScaleFactor = isWeb ? 1.5 : 1.0;

    return SizedBox(
      height: 50,
      width: width,
      child: Stack(
        children: [
          Center(
            child: Image.asset(
              "assets/images/888-02.png",
              width: width,
              height: 50,
              fit: BoxFit.fill, // Ensure image fills the width
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.7, vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  textAlign: TextAlign.center,
                  "اياتها\n${getVerseCount(e["surah"])}",
                  style: TextStyle(
                      fontSize: 6 * textScaleFactor,
                      fontFamily: "UthmanicHafs13"),
                ),
                Center(
                    child: RichText(
                        text: TextSpan(
                  text: e["surah"].toString(),
                  style: TextStyle(
                      fontFamily: "arsura",
                      fontSize: 22 * textScaleFactor,
                      color: Colors.black),
                ))),
                Text(
                  "ترتيبها\n${e["surah"]}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 6 * textScaleFactor,
                      fontFamily: "UthmanicHafs13"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
