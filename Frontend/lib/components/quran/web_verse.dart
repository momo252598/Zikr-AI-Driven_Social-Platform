import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/quran.dart';
import '../../base/res/styles/app_styles.dart';

/// Shows a popup near the verse for web users
void showWebVersePopup(
  BuildContext context,
  int pageNumber,
  int surahNumber,
  int verseNumber,
  Offset position, {
  Function? onClose,
}) {
  // Calculate position to show popup
  final size = MediaQuery.of(context).size;
  final screenWidth = size.width;
  final screenHeight = size.height;

  // Store the original onClose callback so we can call it after removing the overlay
  final originalOnClose = onClose;

  // Declare overlay entry first
  late OverlayEntry entry;

  // Create overlay entry
  entry = OverlayEntry(
    builder: (context) {
      return Stack(
        children: [
          // Dismissible background
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // Remove the overlay when clicking outside
                entry.remove();
                // Call the original onClose callback to reset highlight
                if (originalOnClose != null) {
                  originalOnClose();
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),

          // Position the popup near the verse
          Positioned(
            // Prefer showing popup on the right side if there's enough space
            left: position.dx < screenWidth / 2 ? position.dx : null,
            right: position.dx >= screenWidth / 2
                ? (screenWidth - position.dx - 20)
                : null,
            // Position above or below the verse depending on space
            top: position.dy > screenHeight / 2 ? null : position.dy + 30,
            bottom: position.dy > screenHeight / 2
                ? (screenHeight - position.dy + 30)
                : null,
            child: Material(
              color: Colors.transparent,
              child: WebVersePopupContent(
                pageNumber: pageNumber,
                surahNumber: surahNumber,
                verseNumber: verseNumber,
                onClose: () {
                  entry.remove();
                  // Call the original onClose callback to reset highlight
                  if (originalOnClose != null) {
                    originalOnClose();
                  }
                },
              ),
            ),
          ),
        ],
      );
    },
  );

  // Add the overlay to the screen
  Overlay.of(context).insert(entry);
}

class WebVersePopupContent extends StatelessWidget {
  final int pageNumber;
  final int surahNumber;
  final int verseNumber;
  final Function? onClose;

  const WebVersePopupContent({
    Key? key,
    required this.pageNumber,
    required this.surahNumber,
    required this.verseNumber,
    this.onClose,
  }) : super(key: key);

  // Helper method to safely get font size based on screen width
  double getFontSize(BuildContext context, double size) {
    // Use more conservative font scaling for web
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth < 600 ? 0.8 : 1.0;
    return size * scaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to adjust sizing
    final screenWidth = MediaQuery.of(context).size.width;

    // Make popup width responsive to screen size
    final popupWidth = screenWidth < 500 ? screenWidth * 0.8 : 300.0;

    return Container(
      width: popupWidth,
      constraints: BoxConstraints(
        maxHeight: 300,
        maxWidth: screenWidth * 0.9, // Ensure popup doesn't exceed screen width
      ),
      decoration: BoxDecoration(
        color: AppStyles.bgColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppStyles.boxShadow.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.close, size: 20, color: AppStyles.txtFieldColor),
              onPressed: () {
                if (onClose != null) onClose!();
              },
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(), // Remove minimum size constraints
            ),
          ),

          // Header with decorative element - Fixed sizing
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppStyles.boxShadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Keep column as small as possible
              children: [
                // Surah Name - Fixed font size
                Text(
                  "سورة ${getSurahNameArabic(surahNumber)}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: getFontSize(
                        context, 18), // Fixed size instead of using .sp
                    fontWeight: FontWeight.bold,
                    fontFamily: "Taha",
                    color: AppStyles.darkPurple,
                  ),
                  overflow: TextOverflow.ellipsis, // Prevent text overflow
                ),

                // Decorative divider - Simplified
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 50),
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppStyles.lightPurple,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Verse Number - Fixed font size
                Text(
                  "الآية $verseNumber",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: getFontSize(
                        context, 16), // Fixed size instead of using .sp
                    fontFamily: "Taha",
                    color: AppStyles.txtFieldColor,
                  ),
                  overflow: TextOverflow.ellipsis, // Prevent text overflow
                ),
              ],
            ),
          ),

          const SizedBox(height: 12), // Reduced vertical spacing

          // Action Buttons Row - Fixed sizing
          Container(
            margin: const EdgeInsets.fromLTRB(
                16, 0, 16, 16), // Reduced bottom margin
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bookmark Button
                _buildIconButton(
                  context,
                  icon: Icons.bookmark_border,
                  backgroundColor: AppStyles.lightPurple,
                ),

                // Play Button
                _buildTextButton(
                  context,
                  icon: Icons.play_arrow,
                  text: "تشغيل",
                  backgroundColor: AppStyles.darkPurple,
                ),

                // Tafsir Button
                _buildTextButton(
                  context,
                  icon: Icons.menu_book,
                  text: "التفسير",
                  backgroundColor: AppStyles.txtFieldColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build icon buttons with fixed sizing
  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 4, // Reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      width: 36, // Reduced fixed size
      height: 36, // Reduced fixed size
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 16),
        onPressed: () {},
        padding: EdgeInsets.zero, // Remove padding
        constraints: BoxConstraints(), // Remove constraints
      ),
    );
  }

  // Helper method to build text+icon buttons with fixed sizing
  Widget _buildTextButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 4, // Reduced blur
            offset: const Offset(0, 2),
          ),
        ],
      ),
      height: 36, // Reduced fixed size
      width: 80, // Reduced fixed size
      child: MaterialButton(
        onPressed: () {},
        padding:
            EdgeInsets.symmetric(horizontal: 6, vertical: 0), // Reduced padding
        materialTapTargetSize:
            MaterialTapTargetSize.shrinkWrap, // Reduce tap target
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Keep row as small as possible
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 14), // Smaller icon
            const SizedBox(width: 3), // Reduced spacing
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontFamily: "Taha",
                fontSize:
                    getFontSize(context, 11), // Fixed size instead of using .sp
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
