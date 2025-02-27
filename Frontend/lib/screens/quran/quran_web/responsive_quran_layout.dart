import 'package:flutter/material.dart';
import 'package:software_graduation_project/screens/quran/quran_sura_page.dart';
import 'package:software_graduation_project/screens/quran/quran_page.dart';
import '../../../base/res/styles/app_styles.dart';

class ResponsiveQuranLayout extends StatefulWidget {
  final dynamic suraJsonData;

  const ResponsiveQuranLayout({Key? key, required this.suraJsonData})
      : super(key: key);

  @override
  _ResponsiveQuranLayoutState createState() => _ResponsiveQuranLayoutState();
}

class _ResponsiveQuranLayoutState extends State<ResponsiveQuranLayout> {
  int _selectedPageNumber = 1; // Default to first page

  void _updateSelectedPage(int pageNumber) {
    if (pageNumber != _selectedPageNumber) {
      setState(() {
        _selectedPageNumber = pageNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Row with Directionality to ensure correct RTL layout
    return Directionality(
      textDirection: TextDirection.ltr, // Override parent RTL for this layout
      child: Row(
        children: [
          // Left panel - Sura list (30% width)
          Container(
            width: MediaQuery.of(context).size.width * 0.3,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppStyles.lightPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: QuranPage2(
              suraJsonData: widget.suraJsonData,
              isWeb: true,
              onPageSelected: _updateSelectedPage,
            ),
          ),

          // Right panel - Quran content (70%)
          Expanded(
            child: QuranViewPage(
              key: ValueKey<int>(
                  _selectedPageNumber), // Force rebuild when page changes
              pageNumber: _selectedPageNumber,
              jsonData: widget.suraJsonData,
              shouldHighlightText: false,
              highlightVerse: "",
              isWeb: true, // Pass isWeb flag
            ),
          ),
        ],
      ),
    );
  }
}
