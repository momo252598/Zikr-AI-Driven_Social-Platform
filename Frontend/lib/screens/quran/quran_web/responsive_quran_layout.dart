import 'package:flutter/material.dart';
import 'package:software_graduation_project/screens/quran/quran_sura_page.dart';
import 'package:software_graduation_project/screens/quran/quran_page.dart';
import '../../../base/res/styles/app_styles.dart';

class ResponsiveQuranLayout extends StatefulWidget {
  final dynamic suraJsonData;
  final int initialPage;
  final bool shouldHighlightText; // Add this
  final String highlightVerse; // Add this

  const ResponsiveQuranLayout({
    Key? key,
    required this.suraJsonData,
    this.initialPage = 1, // Default to first page if not specified
    this.shouldHighlightText = false, // Default to false
    this.highlightVerse = "", // Default to empty
  }) : super(key: key);

  @override
  _ResponsiveQuranLayoutState createState() => _ResponsiveQuranLayoutState();
}

class _ResponsiveQuranLayoutState extends State<ResponsiveQuranLayout> {
  late int _selectedPageNumber; // Will be initialized in initState
  bool _shouldHighlightText = false;
  String _highlightVerse = "";

  @override
  void initState() {
    super.initState();
    _selectedPageNumber =
        widget.initialPage; // Use the initial page passed from widget
    _shouldHighlightText = widget.shouldHighlightText;
    _highlightVerse = widget.highlightVerse;

    // Clear highlight after a delay to ensure the popup has time to show
    if (_shouldHighlightText && _highlightVerse.isNotEmpty) {
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _shouldHighlightText = false;
            _highlightVerse = "";
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(ResponsiveQuranLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the initialPage prop has changed, update the selected page number
    if (oldWidget.initialPage != widget.initialPage) {
      print(
          "ResponsiveQuranLayout updated with new initialPage: ${widget.initialPage}");
      setState(() {
        _selectedPageNumber = widget.initialPage;
      });
    }

    // Handle highlight changes from parent
    if (oldWidget.shouldHighlightText != widget.shouldHighlightText ||
        oldWidget.highlightVerse != widget.highlightVerse) {
      setState(() {
        _shouldHighlightText = widget.shouldHighlightText;
        _highlightVerse = widget.highlightVerse;
      });

      // Clear highlight after a delay to ensure the popup has time to show
      if (_shouldHighlightText && _highlightVerse.isNotEmpty) {
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _shouldHighlightText = false;
              _highlightVerse = "";
            });
          }
        });
      }
    }
  }

  void _updateSelectedPage(int pageNumber) {
    if (pageNumber != _selectedPageNumber) {
      setState(() {
        _selectedPageNumber = pageNumber;
        // Clear any highlight when manually changing pages
        _shouldHighlightText = false;
        _highlightVerse = "";
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
              key: ValueKey<String>(
                  '${_selectedPageNumber}_${_shouldHighlightText}_${_highlightVerse}'), // Force rebuild when any parameter changes
              pageNumber: _selectedPageNumber,
              jsonData: widget.suraJsonData,
              shouldHighlightText: _shouldHighlightText, // Use state variable
              highlightVerse: _highlightVerse, // Use state variable
              isWeb: true, // Pass isWeb flag
            ),
          ),
        ],
      ),
    );
  }
}
